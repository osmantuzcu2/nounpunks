class Picture {
  Picture({this.id, this.selected, this.name, this.transferred, this.minted});

  int? id;
  bool? selected;
  String? name;
  bool? transferred;
  bool? minted;
}

class Pictures {
  Pictures({this.cnpPicture, this.fcnpPicture});

  Picture? cnpPicture;
  Picture? fcnpPicture;
}
