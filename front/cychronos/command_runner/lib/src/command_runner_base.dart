// TODO: Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
// class Awesome {
//   bool get isAwesome => true;
// }
class CommandRunnder{
  Future<void> run (List<String> input) async{
    print('CommandRunnder received arguments: $input');
  }
}