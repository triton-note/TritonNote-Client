library triton_note.page.distributions;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_dialog.dart';
import 'package:paper_elements/paper_tabs.dart';
import 'package:paper_elements/paper_toggle_button.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/catches.dart';
import 'package:triton_note/util/distributions_filters.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/pager.dart';

final _logger = new Logger('DistributionsPage');

@Component(
    selector: 'distributions',
    templateUrl: 'packages/triton_note/page/distributions.html',
    cssUrl: 'packages/triton_note/page/distributions.css',
    useShadowDom: true)
class DistributionsPage extends MainFrame implements DetachAware {
  static const FILTER_CHANGED_EVENT = 'FILTER_CHANGED_EVENT';

  DistributionsPage(Router router) : super(router);

  final Getter<DistributionsFilter> filter = new PipeValue();

  Getter<Element> scroller;
  Getter<Element> scrollBase;
  Getter<Element> toolbar;

  Getter<CoreAnimatedPages> _pages;
  Getter<PaperTabs> _tabs;
  Getter<PaperDialog> _filterDialog;

  int _selectedTab;
  int get _selectedIndex => _selectedTab;
  set _selectedIndex(int v) => _pages.value.selected = _tabs.value.selected = _selectedTab = v;
  Element get selectedPage => root.querySelectorAll("core-animated-pages section")[_selectedIndex];

  _Dmap dmap;

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));
    scroller = new CachedValue(() => (root.querySelector('core-header-panel[main]') as CoreHeaderPanel).scroller);
    scrollBase = _pages;
    toolbar = new CachedValue(() => root.querySelector('core-header-panel[main] core-toolbar'));
    _tabs = new CachedValue(() => root.querySelector('paper-tabs'));
    listenOn(_tabs.value, 'core-select', (target) {
      _pages.value.selected = _selectedTab = int.parse(target.selected.toString());
      _logger.fine("Selected tab: ${_selectedTab}: ${selectedPage.id}");
    });
    _filterDialog = new CachedValue(() => root.querySelector('paper-dialog#distributions-filter'));

    dmap = new _Dmap(this);
  }

  void detach() {
    dmap.detach();
  }

  void openFilter(event) {
    final button = event.target as Element;
    _logger.finest("Open filter dialog");
    _filterDialog.value
      ..shadowRoot.querySelector('#scroller').style.padding = "0"
      ..style.margin = "0"
      ..style.top = "${button.getBoundingClientRect().bottom}px"
      ..style.left = "0"
      ..style.right = "0"
      ..open();
  }

  renewFilter() {
    closeDialog(_filterDialog.value);
    _pages.value.dispatchEvent(new CustomEvent(FILTER_CHANGED_EVENT));
  }

  _listenRenew(proc()) {
    _pages.value.on[FILTER_CHANGED_EVENT].listen((event) async {
      proc();
    });
  }
}

abstract class _Section {
  final DistributionsPage _parent;
  final Element _section;

  _Section(DistributionsPage parent, String id)
      : this._parent = parent,
        this._section = parent.root.querySelector("core-animated-pages section#${id}") {
    _parent._listenRenew(refresh);
  }

  void detach();

  refresh();
}

class _Dmap extends _Section {
  static const refreshDur = const Duration(seconds: 3);
  static GeoInfo _lastCenter;

  _Dmap(DistributionsPage parent) : super(parent, 'dmap') {
    _logger.fine("Creating ${this}: lastPos=${_lastCenter}");
    if (_lastCenter == null) {
      Geo.location().then((v) {
        _lastCenter = v;
      });
    }
    gmapSetter.future.then(_initGMap);
  }

  final FuturedValue<GoogleMap> gmapSetter = new FuturedValue();

  LatLngBounds _bounds;
  GeoInfo get center => _lastCenter;
  bool get isReady => center == null;
  PagingList<Catches> aroundHere;
  Timer _refreshTimer;
  HeatmapLayer heatmap;

  _initGMap(GoogleMap gmap) {
    _logger.info("Setting GoogeMap up");
    _section.querySelector('#gmap expandable-gmap')
      ..on['expanding'].listen((event) => gmap.options.mapTypeControl = true)
      ..on['shrinking'].listen((event) => gmap.options.mapTypeControl = false);

    dragend() {
      _lastCenter = gmap.center;
      _bounds = gmap.bounds;
      _logger.finer(() => "Map moved: ${_lastCenter}, ${_bounds}");
      if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
      _refreshTimer = (_bounds == null) ? null : new Timer(refreshDur, refresh);
    }
    gmap.on('dragend', dragend);
    new Future.delayed(new Duration(seconds: 1), dragend);
  }

  refresh() async {
    _logger.finer("Refreshing list around: ${_bounds}, ${aroundHere}");
    aroundHere = new PagingList(await Catches.inArea(_bounds, _parent.filter.value));
    _section.click();
    _logger.finer(() => "List in around: ${aroundHere}");
  }

  toggleDensity(Event event) async {
    final target = event.target as PaperToggleButton;
    _logger.finer("Toggle map density: ${target.checked}");

    if (target.checked) {
      final allList = new List.from(aroundHere.list);
      while (aroundHere.hasMore) {
        allList.addAll(await aroundHere.more(100));
      }
      final data = allList.map((Catches c) => {'location': c.location.geoinfo, 'weight': c.fish.count});
      heatmap?.setMap(null);
      heatmap = new HeatmapLayer(data);
      heatmap.setMap(await gmapSetter.future);
    } else {
      heatmap?.setMap(null);
    }
  }

  void detach() {
    if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
  }
}
