// nft_overview_helpers_web.dart
import 'dart:html' as html;

void downloadCsv(List<Map<String, dynamic>> data) {
  final headers = [
    'Txn Hash',
    'Method',
    'Block',
    'Age',
    'From',
    'To',
    'Amount',
    'Token Fee',
  ];
  final csvRows = [
    headers.join(','),
    ...data.map((row) => [
      row['txn_hash'],
      row['method'],
      row['block'],
      row['age'],
      row['from'],
      row['to'],
      row['amount'],
      row['token_fee'],
    ].join(',')),
  ].join('\n');

  final blob = html.Blob([csvRows]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "export.csv")
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openMetamaskExtension() {
  html.window.open('chrome-extension://nkbihfbeogaeaoehlefnkodbefgpgknn/home.html', '_blank');
}
