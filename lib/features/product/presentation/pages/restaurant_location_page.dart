import 'package:flutter/material.dart';

class RestaurantLocationPage extends StatelessWidget {
  const RestaurantLocationPage({super.key});

  static const String restaurantName = 'CafeFlow Braga';
  static const String restaurantArea = 'Sekitar Braga, Bandung';
  static const double latitude = -6.9175;
  static const double longitude = 107.6098;

  static const int _zoom = 16;
  static const int _centerTileX = 52357;
  static const int _centerTileY = 34030;
  static const double _tileSize = 256;
  static const double _mapSize = _tileSize * 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C0702),
        foregroundColor: Colors.white,
        title: const Text(restaurantName),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _OsmTileMap()),
                Positioned(
                  right: 12,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'OSM',
                        style: TextStyle(
                          color: Color(0xFF1C0702),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _RestaurantLocationPanel(),
        ],
      ),
    );
  }
}

class _OsmTileMap extends StatelessWidget {
  const _OsmTileMap();

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 3,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(120),
      child: Center(
        child: SizedBox(
          width: RestaurantLocationPage._mapSize,
          height: RestaurantLocationPage._mapSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const _OsmTileGrid(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFD88A16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OsmTileGrid extends StatelessWidget {
  const _OsmTileGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = -1; row <= 1; row++)
          Row(
            children: [
              for (var column = -1; column <= 1; column++)
                Image.network(
                  _tileUrl(column, row),
                  width: RestaurantLocationPage._tileSize,
                  height: RestaurantLocationPage._tileSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: RestaurantLocationPage._tileSize,
                    height: RestaurantLocationPage._tileSize,
                    color: const Color(0xFFDCDCDC),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.map_outlined,
                      color: Color(0xFF6E5C52),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static String _tileUrl(int columnOffset, int rowOffset) {
    final x = RestaurantLocationPage._centerTileX + columnOffset;
    final y = RestaurantLocationPage._centerTileY + rowOffset;
    return 'https://tile.openstreetmap.org/${RestaurantLocationPage._zoom}/$x/$y.png';
  }
}

class _RestaurantLocationPanel extends StatelessWidget {
  const _RestaurantLocationPanel();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.storefront_outlined, color: Color(0xFFD88A16), size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RestaurantLocationPage.restaurantName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    RestaurantLocationPage.restaurantArea,
                    style: TextStyle(
                      color: Color(0xFF6E5C52),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${RestaurantLocationPage.latitude}, '
                    '${RestaurantLocationPage.longitude}',
                    style: TextStyle(color: Color(0xFF8A7A72), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
