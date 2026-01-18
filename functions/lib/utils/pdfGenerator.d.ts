/**
 * PDF Generation Utility
 *
 * Generates PDF documents from HTML content using Puppeteer.
 * Optimized for serverless environments using @sparticuz/chromium.
 */
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
/**
 * Generate a PDF from HTML content
 *
 * @param html - The HTML content to render (can be partial or full document)
 * @param options - PDF generation options
 * @returns PDF buffer and metadata
 */
export declare function generatePdf(html: string, options?: PdfGenerationOptions): Promise<PdfGenerationResult>;
/**
 * Generate a PDF and upload to Cloud Storage
 *
 * @param html - The HTML content to render
 * @param storagePath - Path in Cloud Storage (without bucket)
 * @param options - PDF generation options
 * @returns PDF metadata including signed URL
 */
export declare function generateAndUploadPdf(html: string, storagePath: string, options?: PdfGenerationOptions): Promise<PdfUploadResult>;
/**
 * Generate a unique storage path for a letter PDF
 *
 * @param tenantId - Tenant ID
 * @param letterId - Letter ID
 * @returns Storage path
 */
export declare function generateLetterPdfPath(tenantId: string, letterId: string): string;
/**
 * Convert Markdown to HTML for PDF generation
 * Simple implementation - in production, use a proper markdown parser
 *
 * @param markdown - Markdown content
 * @returns HTML content
 */
export declare function markdownToHtml(markdown: string): string;
//# sourceMappingURL=pdfGenerator.d.ts.map