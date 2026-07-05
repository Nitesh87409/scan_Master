import 'package:pro_image_editor/pro_image_editor.dart';

class DocumentFilters {
  static List<FilterModel> getFilters() {
    return [
      FilterModel(
        name: 'Original',
        filters: [
          [
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
      FilterModel(
        name: 'Lighten',
        filters: [
          [
            1.2, 0, 0, 0, 20,
            0, 1.2, 0, 0, 20,
            0, 0, 1.2, 0, 20,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
      FilterModel(
        name: 'Magic Color',
        filters: [
          [
            1.5, 0, 0, 0, 10,
            0, 1.5, 0, 0, 10,
            0, 0, 1.5, 0, 10,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
      FilterModel(
        name: 'Grayscale',
        filters: [
          [
            0.33, 0.59, 0.11, 0, 0,
            0.33, 0.59, 0.11, 0, 0,
            0.33, 0.59, 0.11, 0, 0,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
      FilterModel(
        name: 'B & W',
        filters: [
          [
            1.5, 1.5, 1.5, 0, -150,
            1.5, 1.5, 1.5, 0, -150,
            1.5, 1.5, 1.5, 0, -150,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
      FilterModel(
        name: 'Eco',
        filters: [
          [
            0.25, 0.45, 0.05, 0, 40,
            0.25, 0.45, 0.05, 0, 40,
            0.25, 0.45, 0.05, 0, 40,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
      FilterModel(
        name: 'No Shadow',
        filters: [
          [
            1.3, 0, 0, 0, 30,
            0, 1.3, 0, 0, 30,
            0, 0, 1.3, 0, 30,
            0, 0, 0, 1, 0,
          ]
        ],
      ),
    ];
  }
}
