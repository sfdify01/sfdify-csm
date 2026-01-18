"use strict";
/**
 * PDF Generation Utility
 *
 * Generates PDF documents from HTML content using Puppeteer.
 * Optimized for serverless environments using @sparticuz/chromium.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generatePdf = generatePdf;
exports.generateAndUploadPdf = generateAndUploadPdf;
exports.generateLetterPdfPath = generateLetterPdfPath;
exports.markdownToHtml = markdownToHtml;
const puppeteer_core_1 = __importDefault(require("puppeteer-core"));
const chromium_1 = __importDefault(require("@sparticuz/chromium"));
const admin_1 = require("../admin");
const config_1 = require("../config");
const logger = __importStar(require("firebase-functions/logger"));
const uuid_1 = require("uuid");
// ============================================================================
// Configuration
// ============================================================================
const DEFAULT_PDF_OPTIONS = {
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
async function getBrowserLaunchOptions() {
    if (config_1.isEmulator) {
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
        args: chromium_1.default.args,
        executablePath: await chromium_1.default.executablePath(),
        headless: chromium_1.default.headless,
        defaultViewport: chromium_1.default.defaultViewport,
    };
}
/**
 * Wrap raw HTML content in the full document template
 */
function wrapHtmlContent(content) {
    return HTML_WRAPPER.replace("{{CONTENT}}", content);
}
/**
 * Calculate SHA-256 hash of buffer
 */
async function calculateHash(buffer) {
    const crypto = await Promise.resolve().then(() => __importStar(require("crypto")));
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
async function generatePdf(html, options = {}) {
    const startTime = Date.now();
    let browser = null;
    try {
        // Merge options with defaults
        const pdfOptions = {
            ...DEFAULT_PDF_OPTIONS,
            ...options,
            margin: { ...DEFAULT_PDF_OPTIONS.margin, ...options.margin },
        };
        // Launch browser
        const launchOptions = await getBrowserLaunchOptions();
        browser = await puppeteer_core_1.default.launch(launchOptions);
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
        });
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
    }
    catch (error) {
        logger.error("[PDF Generator] Failed to generate PDF", { error });
        throw error;
    }
    finally {
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
async function generateAndUploadPdf(html, storagePath, options = {}) {
    // Generate PDF
    const result = await generatePdf(html, options);
    // Calculate hash
    const hash = await calculateHash(result.buffer);
    // Upload to Cloud Storage
    const bucket = admin_1.storage.bucket(config_1.firebaseConfig.storageBucket);
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
function generateLetterPdfPath(tenantId, letterId) {
    const timestamp = new Date().toISOString().split("T")[0];
    const uniqueId = (0, uuid_1.v4)().substring(0, 8);
    return `tenants/${tenantId}/letters/${letterId}/letter_${timestamp}_${uniqueId}.pdf`;
}
/**
 * Convert Markdown to HTML for PDF generation
 * Simple implementation - in production, use a proper markdown parser
 *
 * @param markdown - Markdown content
 * @returns HTML content
 */
function markdownToHtml(markdown) {
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
//# sourceMappingURL=pdfGenerator.js.map