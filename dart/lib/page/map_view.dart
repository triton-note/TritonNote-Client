library triton_note.page.map_view;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/decorator/google_map.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('MapViewPage');

@Component(
    selector: 'map-view',
    templateUrl: 'packages/triton_note/page/map_view.html',
    cssUrl: 'packages/triton_note/page/map_view.css',
    useShadowDom: false)
class MapViewPage extends MainFrame {
  final String from;
  final Report report = new Report.fromMap({});
  GoogleMap gmap;

  MapViewPage(Router router, RouteProvider routeProvider)
      : from = routeProvider.parameters['from'],
        super(router) {
    report.asParam = routeProvider.parameters['report'];
  }

  setGMap(v) {
    _logger.fine("Set gmap: ${v}");
    gmap = v;
    gmap.setCenter(report.location.geoinfo);
    gmap.putMarker(report.location.geoinfo);
    gmap.onClick((geoinfo) {
      gmap.putMarker(geoinfo, true);
    });
  }

  _back() {
    gmap.remove();
    router.go(from, {'report': report.asParam});
  }

  cancel() => rippling(_back);

  submit() => rippling(() {
    report.location.geoinfo = gmap.markers.last.geoinfo;
    _back();
  });
}
