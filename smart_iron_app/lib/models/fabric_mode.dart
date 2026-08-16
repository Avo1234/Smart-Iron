import 'package:flutter/material.dart';

class FabricMode {
  final String name;
  final int targetTemp;
  final int maxTemp;
  final Color color;
  final String tip;

  const FabricMode({
    required this.name,
    required this.targetTemp,
    required this.maxTemp,
    required this.color,
    required this.tip,
  });
}

const List<FabricMode> fabricPresets = [
  FabricMode(name: "Casual", targetTemp: 110, maxTemp: 130, color: Colors.cyan, tip: "Low heat. Iron inside out."),
  FabricMode(name: "Kente", targetTemp: 140, maxTemp: 160, color: Colors.amber, tip: "Medium heat. Use damp cloth."),
  FabricMode(name: "Suits", targetTemp: 150, maxTemp: 170, color: Colors.green, tip: "Medium. Steam recommended."),
  FabricMode(name: "Jeans", targetTemp: 180, maxTemp: 200, color: Colors.blue, tip: "High heat. Iron reverse side."),
  FabricMode(name: "Bedding", targetTemp: 200, maxTemp: 220, color: Colors.orange, tip: "Max heat. Slow steady strokes."),
];