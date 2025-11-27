import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GifImageWidget extends StatefulWidget {
  final String gifPath;

  const GifImageWidget({required this.gifPath});

  @override
  GifImageWidgetState createState() => GifImageWidgetState();
}

class GifImageWidgetState extends State<GifImageWidget> {
  ByteData? _byteData;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  Future<void> _loadGif() async {
    final ByteData data = await rootBundle.load(widget.gifPath);
    setState(() {
      _byteData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    if (_byteData == null) {
      return const CircularProgressIndicator();
    } else {
      return Image.memory(
        _byteData!.buffer.asUint8List(),
        gaplessPlayback: true,
        // height: height * 0.2,
        scale: 1.0,
        fit: BoxFit.contain,
      );
    }
  }
}
