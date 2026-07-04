/**
 * Export service: generates PDF and Excel exports for all report types.
 * Uses pdfkit for PDF and exceljs for Excel.
 */
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');

/**
 * Generate a PDF report buffer from data rows.
 * @param {string} title - Report title
 * @param {string[]} columns - Column headers
 * @param {Array} rows - Array of arrays representing rows
 * @returns {Promise<Buffer>}
 */
function generatePDF(title, columns, rows) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const doc = new PDFDocument({ margin: 40, size: 'A4', layout: 'landscape' });
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    // Header
    doc.fontSize(18).text(title, { align: 'center' });
    doc.fontSize(10).text(`Generated: ${new Date().toLocaleDateString()}`, { align: 'center' });
    doc.moveDown(1);

    // Column widths
    const pageWidth = doc.page.width - 80;
    const colWidth = Math.min(120, pageWidth / Math.max(columns.length, 1));

    // Draw column headers
    let x = 40;
    let y = doc.y;
    doc.fontSize(9).font('Helvetica-Bold');
    columns.forEach(col => {
      doc.text(col, x, y, { width: colWidth, ellipsis: true });
      x += colWidth;
    });

    doc.moveDown(0.3);
    doc.moveTo(40, doc.y).lineTo(40 + colWidth * columns.length, doc.y).stroke();
    doc.moveDown(0.3);

    // Draw rows
    doc.font('Helvetica').fontSize(8);
    rows.forEach(row => {
      x = 40;
      y = doc.y;
      if (y > doc.page.height - 80) {
        doc.addPage();
        y = doc.y;
      }
      row.forEach((cell, i) => {
        doc.text(String(cell ?? ''), x, y, { width: colWidth, ellipsis: true });
        x += colWidth;
      });
      doc.moveDown(0.4);
    });

    doc.end();
  });
}

/**
 * Generate an Excel workbook buffer.
 * @param {string} sheetName
 * @param {string[]} columns
 * @param {Array} rows
 * @returns {Promise<Buffer>}
 */
async function generateExcel(sheetName, columns, rows) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Employee Management System';
  workbook.created = new Date();

  const sheet = workbook.addWorksheet(sheetName);

  // Header row
  sheet.addRow(columns);
  const headerRow = sheet.getRow(1);
  headerRow.font = { bold: true };
  headerRow.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF1A237E' }
  };
  headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };

  // Column widths
  columns.forEach((col, i) => {
    sheet.getColumn(i + 1).width = Math.max(col.length + 4, 15);
  });

  // Data rows
  rows.forEach(row => {
    sheet.addRow(row);
  });

  // Borders
  sheet.eachRow((row, rowNumber) => {
    row.eachCell(cell => {
      cell.border = {
        top: { style: 'thin' },
        left: { style: 'thin' },
        bottom: { style: 'thin' },
        right: { style: 'thin' }
      };
    });
  });

  const buffer = await workbook.xlsx.writeBuffer();
  return buffer;
}

/**
 * Generate a CSV string from data.
 */
function generateCSV(columns, rows) {
  const lines = [columns.join(',')];
  rows.forEach(row => {
    lines.push(row.map(cell => `"${String(cell ?? '').replace(/"/g, '""')}"`).join(','));
  });
  return lines.join('\n');
}

module.exports = { generatePDF, generateExcel, generateCSV };
