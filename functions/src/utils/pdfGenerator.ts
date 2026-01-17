/**
 * PDF Generation Utility
 *
 * Generates PDF documents from HTML content using Puppeteer.
 * Optimized for serverless environments using @sparticuz/chromium.
 */

import puppeteer, { Browser, PDFOptions } from "puppeteer-core";
import chromium from "@sparticuz/chromium";
import { storage } from "../admin";
import { firebaseConfig, isEmulator } from "../config";
import * as logger from "firebase-functions/logger";
import { v4 as uuidv4 } from "uuid";

// ============================================================================
// Types
// ============================================================================

export interface PdfGenerationOptions {
  /** Page format (default: 'Letter') */
  format?: "Letter" | "A4";
  /** Margin settings in CSS format */
  margin?: {
    top?: string;
    right?: string;
    bottom?: string;
    left?: string;
  };
  /** Print background graphics */
  printBackground?: boolean;
  /** Display header and footer */
  displayHeaderFooter?: boolean;
  /** Header HTML template */
  headerTemplate?: string;
  /** Footer HTML template */
  footerTemplate?: string;
}

export interface PdfGenerationResult {
  /** PDF buffer */
  buffer: Buffer;
  /** Number of pages */
  pageCount: number;
  /** File size in bytes */
  sizeBytes: number;
}

export interface PdfUploadResult extends PdfGenerationResult {
  /** Cloud Storage path */
  storagePath: string;
  /** Signed URL for download */
  signedUrl: string;
  /** SHA-256 hash of the PDF */
  hash: string;
}

// ============================================================================
// Configuration
// ============================================================================

const DEFAULT_PDF_OPTIONS: PdfGenerationOptions = {
  format: "Letter",
  margin: {
    top: "1in",
    right: "1in",
    bottom: "1in",
    left: "1in",
  },
  printBackground: true,
  displayHeaderFooter: false,
};

/**
 * Base HTML template with proper styling
 */
const HTML_WRAPPER = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

    * {
      box-sizing: border-box;
    }

    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 12pt;
      line-height: 1.6;
      color: #1a1a1a;
      margin: 0;
      padding: 0;
    }

    h1 {
      font-size: 18pt;
      font-weight: 700;
      margin-bottom: 12pt;
    }

    h2 {
      font-size: 14pt;
      font-weight: 600;
      margin-bottom: 8pt;
    }

    p {
      margin-bottom: 12pt;
    }

    .letterhead {
      text-align: center;
      margin-bottom: 24pt;
      padding-bottom: 12pt;
      border-bottom: 1px solid #e0e0e0;
    }

    .date {
      text-align: right;
      margin-bottom: 24pt;
    }

    .address-block {
      margin-bottom: 24pt;
    }

    .address-block p {
      margin: 0;
      line-height: 1.4;
    }

    .signature-block {
      margin-top: 36pt;
    }

    .signature-line {
      margin-top: 48pt;
      width: 250px;
      border-top: 1px solid #1a1a1a;
      padding-top: 4pt;
    }

    .legal-citation {
      font-style: italic;
      font-size: 10pt;
      color: #666;
    }

    .evidence-index {
      margin-top: 24pt;
      border-top: 1px solid #e0e0e0;
      padding-top: 12pt;
    }

    .evidence-index table {
      width: 100%;
      border-collapse: collapse;
    }

    .evidence-index th,
    .evidence-index td {
      text-align: left;
      padding: 6pt 8pt;
      border-bottom: 1px solid #e0e0e0;
    }

    .evidence-index th {
      font-weight: 600;
      background-color: #f5f5f5;
    }

    @media print {
      body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
    }
  </style>
</head>
<body>
  {{CONTENT}}
</body>
</html>
`;

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Get browser launch options based on environment
 */
async function getBrowserLaunchOptions(): Promise<puppeteer.PuppeteerLaunchOptions> {
  if (isEmulator) {
    // In emulator/development, use local Chrome
    return {
      headless: true,
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu",
      ],
      // Try common Chrome paths
      executablePath: process.platform === "darwin"
        ? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        : process.platform === "win32"
          ? "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
          : "/usr/bin/google-chrome-stable",
    };
  }

  // In production, use @sparticuz/chromium
  return {
    args: chromium.args,
    executablePath: await chromium.executablePath(),
    headless: chromium.headless,
    defaultViewport: chromium.defaultViewport,
  };
}

/**
 * Wrap raw HTML content in the full document template
 */
function wrapHtmlContent(content: string): string {
  return HTML_WRAPPER.replace("{{CONTENT}}", content);
}

/**
 * Calculate SHA-256 hash of buffer
 */
async function calculateHash(buffer: Buffer): Promise<string> {
  const crypto = await import("crypto");
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

// ============================================================================
// Main Functions
// ============================================================================

/**
 * Generate a PDF from HTML content
 *
 * @param html - The HTML content to render (can be partial or full document)
 * @param options - PDF generation options
 * @returns PDF buffer and metadata
 */
export async function generatePdf(
  html: string,
  options: PdfGenerationOptions = {}
): Promise<PdfGenerationResult> {
  const startTime = Date.now();
  let browser: Browser | null = null;

  try {
    // Merge options with defaults
    const pdfOptions: PdfGenerationOptions = {
      ...DEFAULT_PDF_OPTIONS,
      ...options,
      margin: { ...DEFAULT_PDF_OPTIONS.margin, ...options.margin },
    };

    // Launch browser
    const launchOptions = await getBrowserLaunchOptions();
    browser = await puppeteer.launch(launchOptions);

    // Create new page
    const page = await browser.newPage();

    // Set viewport for consistent rendering
    await page.setViewport({ width: 816, height: 1056 }); // 8.5" x 11" at 96dpi

    // Wrap partial HTML in full document if needed
    const fullHtml = html.toLowerCase().includes("<!doctype")
      ? html
      : wrapHtmlContent(html);

    // Set content and wait for fonts to load
    await page.setContent(fullHtml, {
      waitUntil: ["domcontentloaded", "networkidle0"],
      timeout: 30000,
    });

    // Generate PDF
    const pdfBuffer = await page.pdf({
      format: pdfOptions.format,
      margin: pdfOptions.margin,
      printBackground: pdfOptions.printBackground,
      displayHeaderFooter: pdfOptions.displayHeaderFooter,
      headerTemplate: pdfOptions.headerTemplate,
      footerTemplate: pdfOptions.footerTemplate,
      preferCSSPageSize: false,
    } as PDFOptions);

    // Get page count by parsing the PDF
    // Simple heuristic: count /Type /Page occurrences
    const pdfString = pdfBuffer.toString("binary");
    const pageMatches = pdfString.match(/\/Type\s*\/Page[^s]/g);
    const pageCount = pageMatches ? pageMatches.length : 1;

    const duration = Date.now() - startTime;
    logger.info("[PDF Generator] Generated PDF", {
      pageCount,
      sizeBytes: pdfBuffer.length,
      durationMs: duration,
    });

    return {
      buffer: Buffer.from(pdfBuffer),
      pageCount,
      sizeBytes: pdfBuffer.length,
    };
  } catch (error) {
    logger.error("[PDF Generator] Failed to generate PDF", { error });
    throw error;
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

/**
 * Generate a PDF and upload to Cloud Storage
 *
 * @param html - The HTML content to render
 * @param storagePath - Path in Cloud Storage (without bucket)
 * @param options - PDF generation options
 * @returns PDF metadata including signed URL
 */
export async function generateAndUploadPdf(
  html: string,
  storagePath: string,
  options: PdfGenerationOptions = {}
): Promise<PdfUploadResult> {
  // Generate PDF
  const result = await generatePdf(html, options);

  // Calculate hash
  const hash = await calculateHash(result.buffer);

  // Upload to Cloud Storage
  const bucket = storage.bucket(firebaseConfig.storageBucket);
  const file = bucket.file(storagePath);

  await file.save(result.buffer, {
    contentType: "application/pdf",
    metadata: {
      cacheControl: "private, max-age=3600",
      contentDisposition: `inline; filename="${storagePath.split("/").pop()}"`,
      metadata: {
        pageCount: String(result.pageCount),
        hash,
        generatedAt: new Date().toISOString(),
      },
    },
  });

  // Generate signed URL (valid for 1 hour)
  const [signedUrl] = await file.getSignedUrl({
    action: "read",
    expires: Date.now() + 3600 * 1000,
  });

  logger.info("[PDF Generator] Uploaded PDF to storage", {
    storagePath,
    sizeBytes: result.sizeBytes,
    pageCount: result.pageCount,
  });

  return {
    ...result,
    storagePath,
    signedUrl,
    hash,
  };
}

/**
 * Generate a unique storage path for a letter PDF
 *
 * @param tenantId - Tenant ID
 * @param letterId - Letter ID
 * @returns Storage path
 */
export function generateLetterPdfPath(tenantId: string, letterId: string): string {
  const timestamp = new Date().toISOString().split("T")[0];
  const uniqueId = uuidv4().substring(0, 8);
  return `tenants/${tenantId}/letters/${letterId}/letter_${timestamp}_${uniqueId}.pdf`;
}

/**
 * Convert Markdown to HTML for PDF generation
 * Simple implementation - in production, use a proper markdown parser
 *
 * @param markdown - Markdown content
 * @returns HTML content
 */
export function markdownToHtml(markdown: string): string {
  let html = markdown;

  // Headers
  html = html.replace(/^### (.*$)/gim, "<h3>$1</h3>");
  html = html.replace(/^## (.*$)/gim, "<h2>$1</h2>");
  html = html.replace(/^# (.*$)/gim, "<h1>$1</h1>");

  // Bold
  html = html.replace(/\*\*(.*?)\*\*/gim, "<strong>$1</strong>");

  // Italic
  html = html.replace(/\*(.*?)\*/gim, "<em>$1</em>");

  // Line breaks and paragraphs
  html = html.replace(/\n\n/g, "</p><p>");
  html = html.replace(/\n/g, "<br>");

  // Wrap in paragraphs
  html = `<p>${html}</p>`;

  // Clean up empty paragraphs
  html = html.replace(/<p><\/p>/g, "");
  html = html.replace(/<p><br><\/p>/g, "");

  return html;
}
