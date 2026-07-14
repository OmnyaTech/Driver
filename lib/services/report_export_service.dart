import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/app_operational_report.dart';

class ReportExportService {
  Future<void> sharePdf({
    required AppOperationalReport report,
    required String Function(double value) currency,
  }) async {
    final bytes = await _buildPdf(report: report, currency: currency);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Relatorio operacional do Omnya Driver',
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: _fileName(report, 'pdf'),
          ),
        ],
        fileNameOverrides: [_fileName(report, 'pdf')],
      ),
    );
  }

  Future<void> shareExcel({
    required AppOperationalReport report,
    required String Function(double value) currency,
  }) async {
    final bytes = _buildExcel(report: report, currency: currency);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Relatorio operacional do Omnya Driver',
        files: [
          XFile.fromData(
            bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: _fileName(report, 'xlsx'),
          ),
        ],
        fileNameOverrides: [_fileName(report, 'xlsx')],
      ),
    );
  }

  Future<Uint8List> _buildPdf({
    required AppOperationalReport report,
    required String Function(double value) currency,
  }) async {
    final document = pw.Document(
      title: 'Relatorio operacional Omnya Driver',
      author: 'Driver',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Omnya Driver',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Relatorio operacional - ${_periodLabel(report)}'),
          pw.SizedBox(height: 24),
          _pdfSectionTitle('Resumo'),
          _pdfTable([
            ['Receita', currency(report.totalIncome)],
            ['Custos', currency(report.totalOperationalCosts)],
            ['Sobrou', currency(report.netResult)],
            ['Jornadas', '${report.totalJourneys}'],
            ['Entregas', '${report.totalDeliveries}'],
            ['Distancia', '${report.totalDistanceKm.toStringAsFixed(1)} km'],
          ]),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Top plataformas'),
          _pdfTable(
            report.topPlatforms.isEmpty
                ? [
                    ['Sem dados', 'Nenhuma plataforma no periodo'],
                  ]
                : report.topPlatforms
                      .map(
                        (item) => [
                          item.platformName,
                          '${currency(item.income)} | ${item.deliveries} entregas',
                        ],
                      )
                      .toList(),
          ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Custos'),
          _pdfTable(
            report.expenseBreakdown.isEmpty
                ? [
                    ['Sem custos', currency(0)],
                  ]
                : report.expenseBreakdown
                      .map((item) => [item.label, currency(item.amount)])
                      .toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  Uint8List _buildExcel({
    required AppOperationalReport report,
    required String Function(double value) currency,
  }) {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Resumo');

    final summary = workbook['Resumo'];
    summary.appendRow([TextCellValue('Omnya Driver')]);
    summary.appendRow([
      TextCellValue('Periodo'),
      TextCellValue(_periodLabel(report)),
    ]);
    summary.appendRow([]);
    summary.appendRow([TextCellValue('Indicador'), TextCellValue('Valor')]);
    summary.appendRow([
      TextCellValue('Receita'),
      TextCellValue(currency(report.totalIncome)),
    ]);
    summary.appendRow([
      TextCellValue('Custos'),
      TextCellValue(currency(report.totalOperationalCosts)),
    ]);
    summary.appendRow([
      TextCellValue('Sobrou'),
      TextCellValue(currency(report.netResult)),
    ]);
    summary.appendRow([
      TextCellValue('Jornadas'),
      IntCellValue(report.totalJourneys),
    ]);
    summary.appendRow([
      TextCellValue('Entregas'),
      IntCellValue(report.totalDeliveries),
    ]);
    summary.appendRow([
      TextCellValue('Distancia km'),
      DoubleCellValue(report.totalDistanceKm),
    ]);

    final platforms = workbook['Top plataformas'];
    platforms.appendRow([
      TextCellValue('Plataforma'),
      TextCellValue('Receita'),
      TextCellValue('Entregas'),
    ]);
    for (final item in report.topPlatforms) {
      platforms.appendRow([
        TextCellValue(item.platformName),
        DoubleCellValue(item.income),
        IntCellValue(item.deliveries),
      ]);
    }

    final costs = workbook['Custos'];
    costs.appendRow([TextCellValue('Tipo'), TextCellValue('Valor')]);
    for (final item in report.expenseBreakdown) {
      costs.appendRow([
        TextCellValue(item.label),
        DoubleCellValue(item.amount),
      ]);
    }

    final encoded = workbook.encode();
    if (encoded == null) {
      throw StateError('Nao foi possivel gerar a planilha.');
    }
    return Uint8List.fromList(encoded);
  }

  pw.Widget _pdfSectionTitle(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _pdfTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  String _periodLabel(AppOperationalReport report) {
    if (report.startAt == null || report.endAt == null) return 'Periodo atual';
    return '${_formatDate(report.startAt!)} a ${_formatDate(report.endAt!)}';
  }

  String _fileName(AppOperationalReport report, String extension) {
    final suffix = report.startAt == null
        ? 'periodo-atual'
        : '${_formatFileDate(report.startAt!)}-${_formatFileDate(report.endAt ?? report.startAt!)}';
    return 'omnya-driver-relatorio-$suffix.$extension';
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatFileDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
