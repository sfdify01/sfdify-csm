"""
Letter rendering service using WeasyPrint for PDF generation.
"""
import hashlib
import logging
from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Optional

from django.conf import settings
from django.template import Template, Context
from django.utils import timezone
from jinja2 import Environment, FileSystemLoader, select_autoescape

logger = logging.getLogger(__name__)


class LetterService:
    """Service for rendering and managing dispute letters."""

    def __init__(self, tenant=None):
        self.tenant = tenant
        self.template_env = self._setup_jinja_env()

    def _setup_jinja_env(self) -> Environment:
        """Set up Jinja2 environment for letter templates."""
        template_dir = Path(settings.BASE_DIR) / 'templates' / 'letters'
        template_dir.mkdir(parents=True, exist_ok=True)

        return Environment(
            loader=FileSystemLoader(str(template_dir)),
            autoescape=select_autoescape(['html', 'xml']),
            trim_blocks=True,
            lstrip_blocks=True,
        )

    def render_letter_html(self, letter) -> str:
        """
        Render letter HTML from template.

        Args:
            letter: Letter model instance

        Returns:
            Rendered HTML string
        """
        # Build context for template
        context = self._build_template_context(letter)

        # If letter has custom body_html, use it directly
        if letter.body_html:
            template = Template(letter.body_html)
            return template.render(Context(context))

        # Otherwise, use template from letter template
        if letter.template:
            template = Template(letter.template.body_html)
            return template.render(Context(context))

        # Fall back to type-based template
        template_name = f"{letter.type}.html"
        try:
            template = self.template_env.get_template(template_name)
            return template.render(**context)
        except Exception as e:
            logger.warning(f"Template {template_name} not found, using base: {e}")
            template = self.template_env.get_template('base_letter.html')
            return template.render(**context)

    def render_letter_pdf(self, letter) -> tuple[bytes, str]:
        """
        Render letter to PDF using WeasyPrint.

        Args:
            letter: Letter model instance

        Returns:
            Tuple of (PDF bytes, SHA256 hash)
        """
        try:
            from weasyprint import HTML, CSS
        except ImportError:
            raise RuntimeError("WeasyPrint is not installed. Install with: pip install WeasyPrint")

        # Render HTML
        html_content = self.render_letter_html(letter)

        # Wrap in full HTML document if needed
        if not html_content.strip().startswith('<!DOCTYPE'):
            html_content = self._wrap_html(html_content)

        # Get CSS
        css_content = self._get_letter_css()

        # Create PDF
        html = HTML(string=html_content)
        css = CSS(string=css_content)

        pdf_buffer = BytesIO()
        html.write_pdf(pdf_buffer, stylesheets=[css])
        pdf_bytes = pdf_buffer.getvalue()

        # Calculate hash
        pdf_hash = hashlib.sha256(pdf_bytes).hexdigest()

        return pdf_bytes, pdf_hash

    def _build_template_context(self, letter) -> dict:
        """Build template context from letter and related objects."""
        dispute = letter.dispute
        consumer = dispute.consumer
        tradeline = dispute.tradeline

        # Get current address
        current_address = consumer.current_address or {}
        if consumer.addresses:
            for addr in consumer.addresses:
                if addr.get('type') == 'current':
                    current_address = addr
                    break
            if not current_address and consumer.addresses:
                current_address = consumer.addresses[0]

        context = {
            # Date
            'current_date': datetime.now().strftime('%B %d, %Y'),
            'date': datetime.now().strftime('%B %d, %Y'),

            # Consumer info
            'consumer': {
                'first_name': consumer.first_name,
                'middle_name': consumer.middle_name or '',
                'last_name': consumer.last_name,
                'full_name': consumer.full_name,
                'ssn_last4': consumer.ssn_last4,
                'dob': consumer.dob.strftime('%m/%d/%Y') if consumer.dob else '',
                'address': current_address,
            },

            # Dispute info
            'dispute': {
                'number': dispute.dispute_number,
                'type': dispute.get_type_display(),
                'bureau': dispute.bureau.title(),
                'narrative': dispute.narrative,
                'reason_codes': dispute.reason_codes,
                'submitted_at': dispute.submitted_at,
                'due_at': dispute.due_at,
            },

            # Tradeline info (if exists)
            'tradeline': None,

            # Recipient info
            'recipient': {
                'name': letter.recipient_name,
                'type': letter.recipient_type,
                'address': letter.recipient_address,
            },

            # Return address
            'return_address': letter.return_address,

            # Bureau addresses
            'bureau_addresses': self._get_bureau_addresses(),
        }

        if tradeline:
            context['tradeline'] = {
                'creditor_name': tradeline.creditor_name,
                'account_number': tradeline.account_number_masked,
                'account_type': tradeline.account_type,
                'current_balance': tradeline.current_balance,
                'opened_date': tradeline.opened_date,
                'account_status': tradeline.account_status,
            }

        return context

    def _get_bureau_addresses(self) -> dict:
        """Get standard bureau dispute addresses."""
        return {
            'equifax': {
                'name': 'Equifax Information Services LLC',
                'line1': 'P.O. Box 740256',
                'city': 'Atlanta',
                'state': 'GA',
                'zip': '30374-0256',
            },
            'experian': {
                'name': 'Experian',
                'line1': 'P.O. Box 4500',
                'city': 'Allen',
                'state': 'TX',
                'zip': '75013',
            },
            'transunion': {
                'name': 'TransUnion LLC',
                'line1': 'Consumer Dispute Center',
                'line2': 'P.O. Box 2000',
                'city': 'Chester',
                'state': 'PA',
                'zip': '19016',
            },
        }

    def _wrap_html(self, content: str) -> str:
        """Wrap HTML content in full document structure."""
        return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Credit Dispute Letter</title>
</head>
<body>
{content}
</body>
</html>"""

    def _get_letter_css(self) -> str:
        """Get CSS styles for letter rendering."""
        return """
@page {
    size: letter;
    margin: 1in;
}

body {
    font-family: "Times New Roman", Times, serif;
    font-size: 12pt;
    line-height: 1.5;
    color: #000;
}

.letterhead {
    margin-bottom: 2em;
}

.date {
    margin-bottom: 2em;
}

.recipient-address {
    margin-bottom: 2em;
}

.salutation {
    margin-bottom: 1em;
}

.body {
    margin-bottom: 2em;
    text-align: justify;
}

.body p {
    margin-bottom: 1em;
}

.signature-block {
    margin-top: 3em;
}

.signature-line {
    border-top: 1px solid #000;
    width: 250px;
    margin-top: 3em;
    margin-bottom: 0.5em;
}

.enclosures {
    margin-top: 2em;
    font-size: 11pt;
}

.legal-notice {
    margin-top: 2em;
    font-size: 10pt;
    font-style: italic;
}

h1 {
    font-size: 14pt;
    font-weight: bold;
    text-align: center;
    margin-bottom: 1em;
}

h2 {
    font-size: 12pt;
    font-weight: bold;
    margin-top: 1em;
    margin-bottom: 0.5em;
}

ul, ol {
    margin-left: 1.5em;
    margin-bottom: 1em;
}

li {
    margin-bottom: 0.5em;
}

.account-info {
    background: #f5f5f5;
    padding: 1em;
    margin: 1em 0;
    border: 1px solid #ddd;
}

.account-info table {
    width: 100%;
}

.account-info td {
    padding: 0.25em 0;
}

.account-info td:first-child {
    font-weight: bold;
    width: 40%;
}
"""

    async def upload_pdf_to_s3(self, pdf_bytes: bytes, letter) -> str:
        """
        Upload PDF to S3 and return URL.

        Args:
            pdf_bytes: PDF file content
            letter: Letter model instance

        Returns:
            S3 URL string
        """
        try:
            import boto3
            from botocore.exceptions import ClientError
        except ImportError:
            raise RuntimeError("boto3 is not installed. Install with: pip install boto3")

        s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_S3_REGION_NAME,
        )

        bucket = settings.AWS_STORAGE_BUCKET_NAME
        key = f"letters/{letter.dispute.consumer.tenant.slug}/{letter.dispute.dispute_number}/{letter.id}.pdf"

        try:
            s3_client.put_object(
                Bucket=bucket,
                Key=key,
                Body=pdf_bytes,
                ContentType='application/pdf',
                ServerSideEncryption='AES256',
            )

            # Generate URL
            url = f"https://{bucket}.s3.amazonaws.com/{key}"
            return url

        except ClientError as e:
            logger.error(f"Failed to upload PDF to S3: {e}")
            raise

    def render_and_save(self, letter) -> dict:
        """
        Render letter to PDF and save to storage.

        Args:
            letter: Letter model instance

        Returns:
            Dict with pdf_url, pdf_hash, rendered_at
        """
        # Render PDF
        pdf_bytes, pdf_hash = self.render_letter_pdf(letter)

        # Upload to S3 (or save locally in dev)
        if hasattr(settings, 'AWS_STORAGE_BUCKET_NAME') and settings.AWS_STORAGE_BUCKET_NAME:
            import asyncio
            pdf_url = asyncio.run(self.upload_pdf_to_s3(pdf_bytes, letter))
        else:
            # Local storage for development
            local_path = Path(settings.MEDIA_ROOT) / 'letters' / f"{letter.id}.pdf"
            local_path.parent.mkdir(parents=True, exist_ok=True)
            local_path.write_bytes(pdf_bytes)
            pdf_url = f"/media/letters/{letter.id}.pdf"

        # Update letter record
        letter.pdf_url = pdf_url
        letter.pdf_hash = pdf_hash
        letter.rendered_at = timezone.now()
        letter.render_version += 1
        letter.save(update_fields=['pdf_url', 'pdf_hash', 'rendered_at', 'render_version'])

        return {
            'pdf_url': pdf_url,
            'pdf_hash': pdf_hash,
            'rendered_at': letter.rendered_at,
            'render_version': letter.render_version,
        }
