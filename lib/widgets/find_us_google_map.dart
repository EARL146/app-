import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'find_us_map_embed_stub.dart'
    if (dart.library.js_interop) 'find_us_map_embed_web.dart';

/// Temporary store pin coordinates in Poblacion, Compostela, Davao de Oro.
const double kBurgerBitesLat = 7.6691;
const double kBurgerBitesLng = 126.0866;

const String _kViewLargerMapUrl =
    'https://www.google.com/maps/search/?api=1&query=$kBurgerBitesLat,$kBurgerBitesLng';

/// Clean Google-Maps-style interactive map for Customer & Guest Home > Find Us,
/// featuring a temporary red BurgerBites pin on Poblacion, Compostela, Davao de Oro.
class FindUsGoogleMap extends StatefulWidget {
  const FindUsGoogleMap({required this.height, super.key});

  final double height;

  @override
  State<FindUsGoogleMap> createState() => _FindUsGoogleMapState();
}

class _FindUsGoogleMapState extends State<FindUsGoogleMap> {
  bool _satelliteMode = false;
  Offset _panOffset = Offset.zero;
  double _zoomLevel = 16.0;
  double _scaleStartZoom = 16.0;
  Offset? _lastFocalPoint;

  bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  void _changeZoom(double delta) {
    setState(() {
      _zoomLevel = (_zoomLevel + delta).clamp(14.0, 18.0);
    });
  }

  void _recenterOnPin() {
    setState(() {
      _panOffset = Offset.zero;
      _zoomLevel = 16.0;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartZoom = _zoomLevel;
    _lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final previousFocal = _lastFocalPoint ?? details.localFocalPoint;
      final delta = details.localFocalPoint - previousFocal;
      _lastFocalPoint = details.localFocalPoint;

      if ((details.scale - 1.0).abs() > 0.01) {
        final zoomDelta = math.log(details.scale) / math.ln2;
        _zoomLevel = (_scaleStartZoom + zoomDelta).clamp(14.0, 18.0);
      }

      const maxPan = 540.0;
      _panOffset = Offset(
        (_panOffset.dx + delta.dx).clamp(-maxPan, maxPan),
        (_panOffset.dy + delta.dy).clamp(-maxPan, maxPan),
      );
    });
  }

  static double _lngToWorldX(double lng, int z) =>
      (lng + 180.0) / 360.0 * 256.0 * (1 << z);

  static double _latToWorldY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    final mercN = math.log(math.tan(math.pi / 4.0 + latRad / 2.0));
    return (1.0 - mercN / math.pi) / 2.0 * 256.0 * (1 << z);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDADCE0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: _buildMapViewport(context),
        ),
      ),
    );
  }

  Widget _buildMapViewport(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final baseTileZ = _zoomLevel.floor().clamp(14, 18);
        final scaleFactor = math.pow(2.0, _zoomLevel - baseTileZ).toDouble();
        final tileDisplaySize = 256.0 * scaleFactor;

        final storeWorldX =
            _lngToWorldX(kBurgerBitesLng, baseTileZ) * scaleFactor;
        final storeWorldY =
            _latToWorldY(kBurgerBitesLat, baseTileZ) * scaleFactor;

        Offset latLngToScreen(double lat, double lng) {
          final px = _lngToWorldX(lng, baseTileZ) * scaleFactor;
          final py = _latToWorldY(lat, baseTileZ) * scaleFactor;
          return Offset(
            viewSize.width / 2 + (px - storeWorldX) + _panOffset.dx,
            viewSize.height / 2 + (py - storeWorldY) + _panOffset.dy,
          );
        }

        final centerWorldX = storeWorldX - _panOffset.dx;
        final centerWorldY = storeWorldY - _panOffset.dy;
        final maxTileIndex = (1 << baseTileZ) - 1;
        final minTx = ((centerWorldX - viewSize.width / 2) / tileDisplaySize)
            .floor()
            .clamp(0, maxTileIndex);
        final maxTx = ((centerWorldX + viewSize.width / 2) / tileDisplaySize)
            .floor()
            .clamp(0, maxTileIndex);
        final minTy = ((centerWorldY - viewSize.height / 2) / tileDisplaySize)
            .floor()
            .clamp(0, maxTileIndex);
        final maxTy = ((centerWorldY + viewSize.height / 2) / tileDisplaySize)
            .floor()
            .clamp(0, maxTileIndex);

        final tileWidgets = <Widget>[];
        if (!_isWidgetTest) {
          final lyrs = _satelliteMode ? 'y' : 'm';
          for (var ty = minTy; ty <= maxTy; ty++) {
            for (var tx = minTx; tx <= maxTx; tx++) {
              final left =
                  viewSize.width / 2 +
                  (tx * tileDisplaySize - storeWorldX) +
                  _panOffset.dx;
              final top =
                  viewSize.height / 2 +
                  (ty * tileDisplaySize - storeWorldY) +
                  _panOffset.dy;
              final hostIdx = (tx + ty).abs() % 4;
              final tileUrl =
                  'https://mt$hostIdx.google.com/vt/lyrs=$lyrs&x=$tx&y=$ty&z=$baseTileZ&hl=en&scale=2';
              tileWidgets.add(
                Positioned(
                  key: ValueKey('gmap-tile-$lyrs-$baseTileZ-$tx-$ty'),
                  left: left,
                  top: top,
                  width: tileDisplaySize + 0.6,
                  height: tileDisplaySize + 0.6,
                  child: IgnorePointer(
                    child: Image.network(
                      tileUrl,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }
          }
        }

        final pinScreenPos = latLngToScreen(kBurgerBitesLat, kBurgerBitesLng);
        final cardMaxWidth = (viewSize.width - 20).clamp(130.0, 225.0);

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _changeZoom(event.scrollDelta.dy < 0 ? 0.35 : -0.35);
            }
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 1. Pan/zoom gesture surface + offline/loading Compostela vector base map
              Positioned.fill(
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onDoubleTap: () => _changeZoom(0.6),
                    child: CustomPaint(
                      painter: _GoogleMapsVectorBasePainter(
                        latLngToScreen: latLngToScreen,
                        panOffset: _panOffset,
                        zoomLevel: _zoomLevel,
                        satelliteMode: _satelliteMode,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),

              // 2. Real high-DPI Google Maps road / satellite tiles
              ...tileWidgets,

              // 3. Temporary red BurgerBites Google Maps marker
              _buildTemporaryBurgerBitesRedMark(pinScreenPos, viewSize),

              // 4. Clean Google Maps top-left place card
              Positioned(
                top: 10,
                left: 10,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: _GooglePlaceInfoCard(
                    onTapTitle: _recenterOnPin,
                    onViewLargerMap: () =>
                        openExternalGoogleMapsUrl(context, _kViewLargerMapUrl),
                  ),
                ),
              ),

              // 5. Google Maps corner layer thumbnail toggle (unlabeled square)
              Positioned(
                left: 10,
                bottom: 22,
                child: Tooltip(
                  message: 'Toggle map view',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _satelliteMode = !_satelliteMode),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _satelliteMode
                                ? const [Color(0xFFF8F9FA), Color(0xFFDADCE0)]
                                : const [Color(0xFF14532D), Color(0xFF064E3B)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x38000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _satelliteMode
                              ? Icons.map_rounded
                              : Icons.layers_rounded,
                          size: 18,
                          color: _satelliteMode
                              ? const Color(0xFF202124)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 6. Google Maps bottom-right +/- zoom pill
              Positioned(
                right: 10,
                bottom: 22,
                child: Container(
                  width: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        onTap: () => _changeZoom(0.5),
                        child: const SizedBox(
                          width: 38,
                          height: 35,
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 1,
                        color: const Color(0xFFE8EAED),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        onTap: () => _changeZoom(-0.5),
                        child: const SizedBox(
                          width: 38,
                          height: 35,
                          child: Icon(
                            Icons.remove_rounded,
                            size: 20,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Subtle Google Maps bottom scale strip
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha: 0.82),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Compostela, Davao de Oro',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF3C4043),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _scaleLabelForZoom(_zoomLevel),
                              style: const TextStyle(
                                color: Color(0xFF3C4043),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 32,
                              height: 5,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Color(0xFF3C4043)),
                                  right: BorderSide(color: Color(0xFF3C4043)),
                                  bottom: BorderSide(color: Color(0xFF3C4043)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _scaleLabelForZoom(double zoom) {
    if (zoom >= 17.5) return '25 m';
    if (zoom >= 16.5) return '50 m';
    if (zoom >= 15.5) return '100 m';
    return '200 m';
  }

  Widget _buildTemporaryBurgerBitesRedMark(Offset screenPos, Size viewSize) {
    if (screenPos.dx < -100 ||
        screenPos.dx > viewSize.width + 100 ||
        screenPos.dy < -100 ||
        screenPos.dy > viewSize.height + 100) {
      return const SizedBox.shrink();
    }

    // Classic Google Maps red teardrop pin with sharp tip anchored at screenPos,
    // paired with a crisp red BurgerBites label right beside the pin.
    return Positioned(
      left: screenPos.dx - 15,
      top: screenPos.dy - 36,
      child: GestureDetector(
        onTap: _recenterOnPin,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CustomPaint(
              size: Size(30, 38),
              painter: _GoogleTeardropPinPainter(
                fillColor: Color(0xFFEA4335),
                innerDotColor: Color(0xFF960B0B),
              ),
            ),
            const SizedBox(width: 3),
            Transform.translate(
              offset: const Offset(0, -5),
              child: Stack(
                children: [
                  Text(
                    'BurgerBites',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3.5
                        ..strokeJoin = StrokeJoin.round
                        ..color = Colors.white,
                    ),
                  ),
                  const Text(
                    'BurgerBites',
                    style: TextStyle(
                      color: Color(0xFFC5221F),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                    ),
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

class _GooglePlaceInfoCard extends StatelessWidget {
  const _GooglePlaceInfoCard({
    required this.onTapTitle,
    required this.onViewLargerMap,
  });

  final VoidCallback onTapTitle;
  final VoidCallback onViewLargerMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTapTitle,
            child: const Text(
              'BurgerBites',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Poblacion, Compostela, Davao de Oro',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: onViewLargerMap,
            child: const Text(
              'View larger map',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF1A73E8),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleTeardropPinPainter extends CustomPainter {
  const _GoogleTeardropPinPainter({
    required this.fillColor,
    required this.innerDotColor,
  });

  final Color fillColor;
  final Color innerDotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final tipY = size.height - 2;
    const headRadius = 11.0;
    const headCenterY = 12.0;

    // Ground shadow ellipse right under the pin tip
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, tipY + 0.5),
        width: 12,
        height: 4,
      ),
      Paint()..color = const Color(0x45000000),
    );

    final pinPath = Path()
      ..moveTo(centerX, tipY)
      ..cubicTo(
        centerX - 3.2,
        tipY - 8.5,
        centerX - headRadius,
        headCenterY + 5.5,
        centerX - headRadius,
        headCenterY,
      )
      ..arcToPoint(
        Offset(centerX + headRadius, headCenterY),
        radius: const Radius.circular(headRadius),
        largeArc: true,
      )
      ..cubicTo(
        centerX + headRadius,
        headCenterY + 5.5,
        centerX + 3.2,
        tipY - 8.5,
        centerX,
        tipY,
      )
      ..close();

    canvas.drawPath(pinPath, Paint()..color = fillColor);
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(centerX, headCenterY),
      4.2,
      Paint()..color = innerDotColor,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleTeardropPinPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.innerDotColor != innerDotColor;
}

/// Google-Maps-styled vector base map of Compostela, Davao de Oro
/// used beneath live Google tiles and as an offline / widget-test map layer.
class _GoogleMapsVectorBasePainter extends CustomPainter {
  const _GoogleMapsVectorBasePainter({
    required this.latLngToScreen,
    required this.panOffset,
    required this.zoomLevel,
    required this.satelliteMode,
  });

  final Offset Function(double lat, double lng) latLngToScreen;
  final Offset panOffset;
  final double zoomLevel;
  final bool satelliteMode;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = satelliteMode
            ? const Color(0xFF162920)
            : const Color(0xFFF1F3F4),
    );

    final parkPaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFF1F4230)
          : const Color(0xFFCEEAD6);
    _drawGeoRect(canvas, 7.6690, 126.0851, 7.6675, 126.0863, parkPaint);
    _drawGeoRect(canvas, 7.6730, 126.0835, 7.6714, 126.0852, parkPaint);
    _drawGeoRect(canvas, 7.6668, 126.0882, 7.6652, 126.0902, parkPaint);

    final riverPoints = <Offset>[
      latLngToScreen(7.6790, 126.0938),
      latLngToScreen(7.6740, 126.0924),
      latLngToScreen(7.6695, 126.0918),
      latLngToScreen(7.6650, 126.0905),
      latLngToScreen(7.6600, 126.0894),
    ];
    final riverPath = Path()..moveTo(riverPoints.first.dx, riverPoints.first.dy);
    for (final pt in riverPoints.skip(1)) {
      riverPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = satelliteMode
            ? const Color(0xFF0E3A5D)
            : const Color(0xFF9CC0F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    const gridLats = <double>[
      7.6650,
      7.6664,
      7.6678,
      7.6692,
      7.6706,
      7.6722,
      7.6746,
    ];
    const gridLngs = <double>[
      126.0825,
      126.0840,
      126.0853,
      126.0866,
      126.0880,
      126.0896,
    ];

    final streetCasePaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFF334155)
          : const Color(0xFFDADCE0)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final streetFillPaint = Paint()
      ..color = satelliteMode
          ? const Color(0xFF475569)
          : const Color(0xFFFFFFFF)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final lat in gridLats) {
      final a = latLngToScreen(lat, 126.0805);
      final b = latLngToScreen(lat, 126.0925);
      canvas.drawLine(a, b, streetCasePaint);
    }
    for (final lng in gridLngs) {
      final a = latLngToScreen(7.6625, lng);
      final b = latLngToScreen(7.6765, lng);
      canvas.drawLine(a, b, streetCasePaint);
    }
    for (final lat in gridLats) {
      final a = latLngToScreen(lat, 126.0805);
      final b = latLngToScreen(lat, 126.0925);
      canvas.drawLine(a, b, streetFillPaint);
    }
    for (final lng in gridLngs) {
      final a = latLngToScreen(7.6625, lng);
      final b = latLngToScreen(7.6765, lng);
      canvas.drawLine(a, b, streetFillPaint);
    }

    final cateelStart = latLngToScreen(7.6690, 126.0865);
    final cateelEnd = latLngToScreen(7.6684, 126.0960);
    canvas.drawLine(
      cateelStart,
      cateelEnd,
      Paint()
        ..color = const Color(0xFFE5C158)
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      cateelStart,
      cateelEnd,
      Paint()
        ..color = const Color(0xFFFEF7E0)
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );

    final hwySouth = latLngToScreen(7.6605, 126.0822);
    final hwyMid = latLngToScreen(7.6691, 126.0866);
    final hwyNorth = latLngToScreen(7.6780, 126.0908);
    final hwyPath = Path()
      ..moveTo(hwySouth.dx, hwySouth.dy)
      ..lineTo(hwyMid.dx, hwyMid.dy)
      ..lineTo(hwyNorth.dx, hwyNorth.dy);

    canvas.drawPath(
      hwyPath,
      Paint()
        ..color = const Color(0xFFE37400)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      hwyPath,
      Paint()
        ..color = const Color(0xFFFDD663)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _drawRoadLabel(
      canvas,
      latLngToScreen(7.6678, 126.0836),
      'F. Dagohoy St',
    );
    _drawRoadLabel(
      canvas,
      latLngToScreen(7.6706, 126.0842),
      'Magsaysay Ave',
    );
    _drawRoadLabel(
      canvas,
      latLngToScreen(7.6687, 126.0902),
      'Compostela-Cateel Rd',
    );
    _drawHighwayShield(canvas, latLngToScreen(7.6656, 126.0848), 'AH26');
  }

  void _drawGeoRect(
    Canvas canvas,
    double northLat,
    double westLng,
    double southLat,
    double eastLng,
    Paint paint,
  ) {
    final tl = latLngToScreen(northLat, westLng);
    final br = latLngToScreen(southLat, eastLng);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(tl, br),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  void _drawRoadLabel(Canvas canvas, Offset pos, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: satelliteMode ? Colors.white70 : const Color(0xFF5F6368),
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos.translate(-tp.width / 2, -tp.height / 2));
  }

  void _drawHighwayShield(Canvas canvas, Offset pos, String code) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: 32, height: 15),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF1A73E8));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GoogleMapsVectorBasePainter oldDelegate) =>
      oldDelegate.panOffset != panOffset ||
      oldDelegate.zoomLevel != zoomLevel ||
      oldDelegate.satelliteMode != satelliteMode;
}
