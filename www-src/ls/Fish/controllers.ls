.controller 'SNSCtrl', ($log, $scope, $ionicPopup, $ionicModal, AccountFactory) !->
	$ionicModal.fromTemplateUrl 'template/sns.html'
		, (modal) !->
			$scope.open = !->
				init !->
					modal.show!
			$scope.close = !->
				modal.hide!
		,
			scope: $scope
			animation: 'slide-in-left'

	init = (on-success) !->
		$scope.changing = false
		$scope.login = AccountFactory.is-connected!
		$log.info "Social view initialized with value: #{$scope.login}"
		AccountFactory.get-username (username) !->
			$log.debug "Take username: #{username}"
			$scope.username = username
			on-success! if on-success
		, (msg) !->
			$log.debug "Could not take username: #{msg}"
			on-success! if on-success

	$scope.checkSocial = !->
		$scope.changing = true
		next = !AccountFactory.is-connected!
		$log.debug "Changing social: #{next}"
		if next
			AccountFactory.connect (username) !->
				$scope.changing = false
				$scope.username = username
				$log.debug "Account connection: #{next}: #{username}"
			, (msg) !->
				$scope.login = false
				$scope.changing = false
				$ionicPopup.alert do
					title: 'Error'
					template: msg
		else
			AccountFactory.disconnect !->
				$scope.$apply !->
					$scope.changing = false
					$scope.username = null
				$log.debug "Account connection: #{next}"
			, (msg) !->
				$scope.login = true
				$scope.changing = false
				$ionicPopup.alert do
					title: 'Error'
					template: msg

.controller 'PreferencesCtrl', ($log, $scope, $ionicPopup, $ionicModal, UnitFactory) !->
	$ionicModal.fromTemplateUrl 'template/preferences.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-left'
	$scope.open = !->
		init !->
			$scope.modal.show!
	$scope.cancel = !->
		$scope.modal.hide!
	$scope.submit = !->
		UnitFactory.save $scope.unit
		$scope.modal.hide!

	init = (on-success) !->
		# Initialize units
		$scope.units = UnitFactory.units!
		UnitFactory.load (units) !->
			$scope.unit = units
			on-success! if on-success

.controller 'ShowReportsCtrl', ($log, $scope, $state, $stateParams, $ionicPopup, $ionicScrollDelegate, ReportFactory) !->
	$scope.reports = ReportFactory.cachedList
	$scope.hasMoreReports = ReportFactory.hasMore
	$scope.refresh = !->
		ReportFactory.refresh !->
			$scope.$broadcast 'scroll.refreshComplete'
	$scope.moreReports = !->
		ReportFactory.load !->
			$scope.$broadcast 'scroll.infiniteScrollComplete'

	$scope.detail = (index) !->
		$scope.index = index
		$scope.report = ReportFactory.getReport index
		$ionicScrollDelegate.$getByHandle("scroll-img-show-report").zoomTo 1
		$scope.modal.show!
	$scope.close = !-> $scope.modal.hide!
	$scope.delete = (index) !->
		$ionicPopup.confirm do
			title: "Delete Report"
			template: "Are you sure to delete this report ?"
		.then (res) !-> if res
			ReportFactory.remove index, !->
				$log.debug "Remove completed."
			$scope.modal.hide!

.controller 'DetailReportCtrl', ($log, $ionicPlatform, $scope, $ionicModal, ReportFactory) !->
	$ionicModal.fromTemplateUrl 'template/view-on-map.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-left'

	$scope.showMap = !->
		$scope.modal.show!.then !->
			onBackbutton = !->
				$scope.gmap-visible = false
				$ionicPlatform.offHardwareBackButton onBackbutton
			$ionicPlatform.onHardwareBackButton onBackbutton
			$scope.gmap-center = $scope.report.location.geoinfo
			$scope.gmap-visible = true
	$scope.closeMap = !->
		$scope.gmap-visible = false
		$scope.modal.hide!

.controller 'EditReportCtrl', ($log, $ionicPlatform, $filter, $scope, $ionicModal, $ionicScrollDelegate, ReportFactory) !->
	# $scope.currentReport = 表示中のレコード
	# $scope.index = 表示中のレコードの index
	$ionicModal.fromTemplateUrl 'template/edit-report.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$ionicModal.fromTemplateUrl 'template/view-on-map.html'
		, (modal) !-> $scope.modal-gmap = modal
		,
			scope: $scope
			animation: 'slide-in-left'

	$scope.title = "Edit Report"

	$scope.showMap = !->
		$scope.modal-gmap.show!.then !->
			onBackbutton = !->
				$scope.gmap-visible = false
				$ionicPlatform.offHardwareBackButton onBackbutton
			$ionicPlatform.onHardwareBackButton onBackbutton
			$scope.gmap-center = $scope.currentReport.location.geoinfo
			$scope.gmap-visible = true
	$scope.closeMap = !->
		$scope.gmap-visible = false
		$scope.modal-gmap.hide!
	$scope.submitMap = !->
		if $scope.gmap-markers?.length > 0 then
			gi = $scope.gmap-markers[0].geoinfo
			$log.debug "Set location: #{angular.toJson gi}"
			$scope.currentReport.location.geoinfo = gi
		$scope.closeMap!
	$scope.gmap-markers = []
	$scope.gmap-onTap = (mg) !->
		for m in $scope.gmap-markers
			if m.geoinfo != mg.geoinfo then
				m.marker.remove!
		$scope.gmap-markers = [mg]

	$scope.edit = !->
		$scope.currentReport = angular.copy $scope.report
		$scope.currentReport.dateAt = $filter('date') new Date($scope.currentReport.dateAt), 'yyyy-MM-dd'
		$ionicScrollDelegate.$getByHandle("scroll-img-edit-report").zoomTo 1
		$scope.modal.show!

	$scope.cancel = !->
		$scope.modal.hide!
	
	$scope.submit = !->
		angular.copy $scope.currentReport, $scope.report
		ReportFactory.update $scope.report, !->
			$log.debug "Edit completed."
		$scope.modal.hide!

.controller 'EditReportGMapCtrl', ($log, $scope, $state, $stateParams, GMapFactory, ReportFactory) !->
	init = !->
		$log.debug "Entering 'EditReportGMapCtrl'"
		GMapFactory.onDiv 'edit-map', (gmap) !->
			GMapFactory.onTap (geoinfo) !->
				$scope.geoinfo = geoinfo
				GMapFactory.put-marker geoinfo
		, $scope.report.location.geoinfo
	$scope.submit = !->
		$scope.report.location.geoinfo = $scope.geoinfo
		$scope.close!
	$scope.close = !->
		$state.go $stateParams.previous

	$log.debug "EditReportGMapCtrl: params=#{angular.toJson $stateParams}"
	$scope.report = ReportFactory.current!
	init!

.controller 'AddReportCtrl', ($log, $filter, $scope, $state, $stateParams, $ionicPopup, $ionicScrollDelegate, PhotoFactory, SessionFactory, ReportFactory) !->
	init = !->
		PhotoFactory.select (photo) !->
			uri = if photo instanceof Blob then URL.createObjectURL(photo) else photo
			$log.debug "Selected photo: #{uri}"
			$ionicScrollDelegate.$getByHandle("scroll-img-new-report").zoomTo 1
			$scope.currentReport = ReportFactory.newCurrent uri
			$scope.submit =
				enabled: false
				publishing: false
			upload = (geoinfo = null) !->
				$scope.currentReport.location.geoinfo = geoinfo
				SessionFactory.start geoinfo, !->
					SessionFactory.put-photo photo
					, (result) !->
						$log.debug "Get result of upload: #{angular.toJson result}"
						$scope.currentReport.photo = angular.copy result.url
						$scope.submit.enabled = true
					, (inference) !->
						$log.debug "Get inference: #{angular.toJson inference}"
						if inference.location
							$scope.currentReport.location.name = that
						if inference.fishes?.length > 0
							$scope.currentReport.fishes = inference.fishes
					, (error) !->
						$ionicPopup.alert do
							title: "Failed to upload"
							template: error
						.then (res) !->
							$scope.cancel!
						, (error) !->
							$ionicPopup.alert do
								title: "Error"
								template: error
			$log.warn "Getting current location..."
			navigator.geolocation.getCurrentPosition (pos) !->
				$log.debug "Gotta geolocation: #{angular.toJson pos}"
				upload do
					latitude: pos.coords.latitude
					longitude: pos.coords.longitude
			, (error) !->
				$log.error "Geolocation Error: #{angular.toJson error}"
				upload!
			, do
				timeout: 1000
		, (error) !->
			$ionicPopup.alert do
				title: "No photo selected"
				template: "Need a photo to report"

	$scope.close = !->
		$state.go 'main'
	$scope.cancel = !-> $scope.close!
	$scope.submit = !->
		report = angular.copy $scope.currentReport
		report.dateAt = new Date(report.dateAt).getTime!
		SessionFactory.finish report, $scope.submit.publishing, !->
			$scope.close!

	$log.debug "AddReportCtrl: params=#{angular.toJson $stateParams}"
	if $stateParams.init
		init!
	else
		$scope.currentReport = ReportFactory.current!
		$log.debug "Getting current report: #{angular.toJson $scope.currentReport}"

.controller 'AddFishCtrl', ($scope, $ionicModal, $ionicPopup, UnitFactory) !->
	# $scope.currentReport.fishes
	fish-template = (o = null) ->
		r =
			name: null
			count: 1
		r <<< o if o
		r.length = {} unless r.length
		r.weight = {} unless r.weight
		UnitFactory.load (units) !->
			r.length.unit = units.length
			r.weight.unit = units.weight
		r
	$ionicModal.fromTemplateUrl 'template/edit-fish.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	show = (func) !->
		$scope.commit = func
		$scope.modal.show!

	$scope.cancel = !->
		$scope.fishIndex = null
		$scope.tmpFish = null
		$scope.modal.hide!
	$scope.submit = !->
		fish = $scope.tmpFish
		if fish.name?.length > 0 && fish.count > 0
		then
			fish.length = null unless fish.length.value
			fish.weight = null unless fish.weight.value
			$scope.commit fish
			$scope.commit = null
			$scope.fishIndex = null
			$scope.tmpFish = null
			$scope.modal.hide!

	$scope.units = UnitFactory.units!
	$scope.addFish = !->
		$scope.tmpFish = fish-template!
		show (fish) !-> $scope.currentReport.fishes.push fish
	$scope.editFish = (index) !->
		$scope.fishIndex = index
		$scope.tmpFish = fish-template $scope.currentReport.fishes[index]
		show (fish) !-> $scope.currentReport.fishes[index] <<< fish
	$scope.deleteFish = (index, confirm = true) !->
		del = !-> $scope.currentReport.fishes.splice index, 1
		if !confirm then del! else
			$ionicPopup.confirm do
				template: "Are you sure to delete this catch ?"
			.then (res) !-> if res
				$scope.modal.hide!
				del!

.controller 'DistributionMapCtrl', ($log, $ionicPlatform, $scope, $state, $filter, $ionicModal, $ionicPopup, GMapFactory, DistributionFactory, ReportFactory) !->
	GMapFactory.onDiv 'distribution-map', (gmap) !->
		$scope.gmap = gmap
		map-distribution!
	$scope.closeMap = !->
		$state.go 'main'

	$scope.showOptions = !->
		$scope.gmap.setClickable false
		$ionicPopup.alert do
			templateUrl: 'distribution-map-options',
			scope: $scope
			title: "Options"
		.then (res) ->
			$scope.gmap.setClickable true
	$scope.view =
		others: false
		name: null
	$scope.$watch 'view.others', (value) !->
		$log.debug "Changing 'view.person': #{angular.toJson value}"
		map-distribution!
	$scope.$watch 'view.name', (value) !->
		$log.debug "Changing 'view.fish': #{angular.toJson value}"
		map-distribution!

	$ionicModal.fromTemplateUrl 'template/show-report.html'
		, (modal) !-> $scope.modal-detail = modal
		,
			scope: $scope
			animation: 'slide-in-up'
	$scope.close = !->
		$scope.modal-detail.hide!
	$scope.delete = (index) !->
		$ionicPopup.confirm do
			title: "Delete Report"
			template: "Are you sure to delete this report ?"
		.then (res) !-> if res
			ReportFactory.remove index, !->
				$log.debug "Remove completed."
			$scope.close!

	icons = [1 to 10] |> _.map (count) ->
		size = 32
		center = size / 2
		r = ->
			min = 4
			max = center - 1
			v = min + (max - min) * count / 10
			_.min max, v
		canvas = document.createElement 'canvas'
		canvas.width = size
		canvas.height = size
		context = canvas.getContext '2d'
		context.beginPath!
		context.strokeStyle = "rgb(80, 0, 0)"
		context.fillStyle = "rgba(255, 40, 0, 0.7)"
		context.arc center, center, r!, 0, _.pi * 2, true
		context.stroke!
		context.fill!
		canvas.toDataURL!
	map-distribution = !->
		gmap = $scope.gmap
		others = $scope.view.others
		fish-name = $scope.view.name

		map-mine = (list) !->
			$log.debug "Mapping my distribution (filtered by '#{fish-name}'): #{list}"
			gmap.clear!
			detail = (fish) -> (marker) !->
				marker.on plugin.google.maps.event.INFO_CLICK, !->
					$log.debug "Detail for fish: #{angular.toJson fish}"
					find-or = (fail) !->
						$scope.index = ReportFactory.getIndex fish.report-id
						if $scope.index >= 0 then
							$scope.report = ReportFactory.getReport $scope.index
							$scope.gmap-visible = false
							$scope.modal-detail.show!
						else fail!
					find-or !->
						ReportFactory.refresh !->
							find-or !->
								$log.error "Report not found by id: #{fish.report-id}"
			for fish in list
				gmap.addMarker do
					title: "#{fish.name} x #{fish.count}"
					snippet: $filter('date') new Date(fish.date), 'yyyy-MM-dd'
					position:
						lat: fish.geoinfo.latitude
						lng: fish.geoinfo.longitude
					, detail fish
		map-others = (list) !->
			$log.debug "Mapping other's distribution (filtered by '#{fish-name}'): #{list}"
			gmap.clear!
			for fish in list
				gmap.addMarker do
					title: "#{fish.name} x #{fish.count}"
					icon: icons[(_.min fish.count, 10) - 1]
					position:
						lat: fish.geoinfo.latitude
						lng: fish.geoinfo.longitude

		if (gmap)
			if !others
			then DistributionFactory.mine fish-name, map-mine
			else DistributionFactory.others fish-name, map-others
