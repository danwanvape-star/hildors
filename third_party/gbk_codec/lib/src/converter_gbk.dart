import 'dart:convert';

import 'gbk_maps.dart';

gbkCodec gbk =  new gbkCodec();

Map<int, String> _gbkCode_to_char = new Map<int, String>();
Map<String, int> _char_to_gbkCode = new Map<String, int>();

class gbkCodec extends Encoding {
  @override
  Converter<List<int>, String> get decoder => const gbkDecoder();

  @override
  Converter<String, List<int>> get encoder => const gbkEncoder();

  @override
  String get name => "gbk";

  gbkCodec(){
    //initialize gbk code maps
    _char_to_gbkCode = json_char_to_gbk;
    json_gbk_to_char.forEach((sInt, sChar) {
      _gbkCode_to_char[int.parse(sInt, radix : 16)] = sChar;
    });

  }
}

class gbkEncoder extends Converter<String, List<int>> {
  const gbkEncoder();

  @override
  List<int> convert(String input) {
    return gbkEncode(input);
  }
}

List<int> gbkEncode(String input) {
  List<int> ret = [];
  input.codeUnits.forEach( (charCode) {
    String char = String.fromCharCode(charCode);
    int? gbkCode = _char_to_gbkCode[char];
    if (gbkCode != null )ret.add(gbkCode);
    else if (charCode != null ) ret.add(charCode);
  });
  return ret;
}

class gbkDecoder extends Converter<List<int>, String> {
  const gbkDecoder();

  @override
  String convert(List<int> input) {
    return gbkDecode(input);
  }
}

String gbkDecode(List<int> input) {
  String ret = '';
  /*
  List<int> combined = new List<int>();
  int id= 0;
  while(id<input.length) {
      int charCode = input[id];
      id ++;
      if (charCode < 0x80 || charCode > 0xffff || id == input.length) {
        combined.add(charCode);
      } else {
        charCode = (charCode << 8) + input[id];
        id ++;
        combined.add(charCode);
      }
  }
  */
  input.forEach((charCode) {
    String? char = _gbkCode_to_char[charCode];
    if (char != null) ret += char;
    else ret += String.fromCharCode(charCode);
    //print(ret);
  });
  return ret;
}
