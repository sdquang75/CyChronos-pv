import "dart:io";
import 'package:http/http.dart' as http;
import 'package:command_runner/command_runner.dart';
// const version = "1.1.1.0";

void main(List<String> arguments) async {
var runner = CommandRunnder();
await runner.run(arguments);


  // if (arguments.isEmpty) {
  //   print("Hello Worlds");
  // } else if (arguments.first == "version") {
  //   print("this version is $version");
  // } else if (arguments.first == "wikipedia") {
  //   final input = arguments.length > 1 ? arguments.sublist(1) : null;
  //   searchWikipedia(input);
  // } else {
  //   printUsage();
  // }
}

// void searchWikipedia(List<String>? arguments) async {
//   final String articleTitle;

//   if (arguments == null || arguments.isEmpty) {
//     print("Please provide an article title");
  
//     final inputFromStdin = stdin.readLineSync();
//     // print('DEBUG - stdin received: "$inputFromStdin"'); // thêm dòng này
//     if (inputFromStdin == null || inputFromStdin.isEmpty) {
//       print('No article title provided. Exiting.');
//       return;
//     }
//     articleTitle = inputFromStdin;
//   } else {
//     articleTitle = arguments.join(' ');
//   }

//   print('Looking up articles about "$articleTitle". Please wait.');
//   var articleContent = await getWikipediaArticle(articleTitle);
//   print(articleContent);
// }

// void printUsage() {
//   print("Search something");
// }

// Future<String> getWikipediaArticle(String articleTitle) async {
//   final url = Uri.https(
//     'en.wikipedia.org',
//     'api/rest_v1/page/summary/$articleTitle',
//   );
//   final response = await http.get(url);

//   if (response.statusCode == 200) {
//     return response.body;
//   }
//   return 'Error to fetch article"$articleTitle". statusCode : ${response.statusCode}';
// }
