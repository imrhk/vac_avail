import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


const district_id = 188;
Future<Null> getAvailability() async {
  tz.initializeTimeZones();
  final ist = tz.getLocation('Asia/Kolkata');
  tz.setLocalLocation(ist);
  final now = tz.TZDateTime.now(ist);

  await Future.wait(Iterable.generate(4)
      .map((e) => _getAvailabilityFromDate(now.add(Duration(days: 7*e))))
      .toList());
}

Future<Null> _getAvailabilityFromDate(tz.TZDateTime localTime) async {
  final localDay =
      localTime.day <= 9 ? '0${localTime.day}' : localTime.day.toString();
  final localMonth =
      localTime.month <= 9 ? '0${localTime.month}' : localTime.month.toString();
  final localYear = localTime.year.toString();

  final url = Uri.parse(
      'https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$district_id&date=$localDay-$localMonth-$localYear');
  //print(url);
  final response =
      await http.get(url.toString(),  headers: {
    'authority': 'cdn-api.co-vin.in',
    'pragma': 'no-cache',
    'cache-control': 'no-cache',
    'sec-ch-ua':
        '" Not A;Brand";v="99", "Chromium";v="90", "Google Chrome";v="90"',
    'accept': 'application/json, text/plain, */*',
    'sec-ch-ua-mobile': '?0',
    'user-agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36',
    'origin': 'https://www.cowin.gov.in',
    'sec-fetch-site': 'cross-site',
    'sec-fetch-mode': 'cors',
    'sec-fetch-dest': 'empty',
    'referer': 'https://www.cowin.gov.in/',
    'accept-language': 'en-US,en;q=0.9,es-ES;q=0.8,es;q=0.7',
  });
  //print(response.body);
  final output = StringBuffer();
  final map = jsonDecode(response.body) as Map;
  final availablePlaces = (map['centers'] as List)
      .where((e) => (e['sessions'] as List)
          .where((e) => e['available_capacity'] > 0 && e['min_age_limit'] == 18)
          .toList()
          .isNotEmpty)
      .toList();
  availablePlaces.forEach((e) {
    output.write(e['name']);
    (e['sessions'] as List)
        .where((e) => e['available_capacity'] > 0 && e['min_age_limit'] == 18)
        .forEach((e) {
      output.write('${e['date']} -> ${e['slots']}');
    });
    output.write('\n');
  });
  final result = output.toString();
  if(result.isNotEmpty) {
    print(result);
  }
}
