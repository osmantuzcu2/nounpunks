import 'dart:convert';

Ipfs ipfsFromJson(String str) => Ipfs.fromJson(json.decode(str));

String ipfsToJson(Ipfs data) => json.encode(data.toJson());

class Ipfs {
  Ipfs({
    this.name,
    this.description,
    this.image,
    this.dna,
    this.edition,
    this.date,
    this.compiler,
  });

  String? name;
  String? description;
  String? image;
  String? dna;
  int? edition;
  int? date;
  String? compiler;

  factory Ipfs.fromJson(Map<String, dynamic> json) => Ipfs(
        name: json["name"] == null ? null : json["name"],
        description: json["description"] == null ? null : json["description"],
        image: json["image"] == null ? null : json["image"],
        dna: json["dna"] == null ? null : json["dna"],
        edition: json["edition"] == null ? null : json["edition"],
        date: json["date"] == null ? null : json["date"],
        compiler: json["compiler"] == null ? null : json["compiler"],
      );

  Map<String, dynamic> toJson() => {
        "name": name == null ? null : name,
        "description": description == null ? null : description,
        "image": image == null ? null : image,
        "dna": dna == null ? null : dna,
        "edition": edition == null ? null : edition,
        "date": date == null ? null : date,
        "compiler": compiler == null ? null : compiler,
      };
}
