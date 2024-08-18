import SwiftUI
import CoreLocation
import MapKit

class ContentViewModel: ObservableObject, LocationGetable {
    /// マップ上のGeofenceサークル半径
    var radius: Double = 500
    /// スピード
    var speed: Double = 0
    /// 現在地の座標
    @Published var currentLocation = CLLocationCoordinate2D(latitude: 35.170915, longitude: 136.881537)
    
    var locationManager: LocationManager = LocationManager()
    
    init() {
        self.locationManager.delegate = self
        self.locationManager.requestLocation()
    }
    
    func didUpdateLocation(_ location: CLLocationCoordinate2D) {
        print("位置情報取得-Success",location)
        self.currentLocation = location
        self.addGeofenceCircle(at: location, radius: self.radius)
    }
    
    func didFailWithError(_ error: any Error) {
        print("位置情報取得-Fail")
    }
    
    func didChangeAuthorizationDenied() {
        print("権限状態-不許可")
    }
    
    /// Geofenceサークル作成
    func addGeofenceCircle(at coordinate: CLLocationCoordinate2D, radius: Double) {
        /// 監視していたGeofenceサークルの削除
        self.removeAllGeofenceRegions()
        let geofenceRegion = CLCircularRegion(center: coordinate, radius: radius, identifier: UUID().uuidString)
        geofenceRegion.notifyOnEntry = false
        geofenceRegion.notifyOnExit = true
        self.calculateArrivalTime()
        self.locationManager.locationManager.startMonitoring(for: geofenceRegion)
    }
    
    /// Geofenceサークル登録履歴削除
    func removeAllGeofenceRegions() {
        for region in locationManager.locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                self.locationManager.locationManager.stopMonitoring(for: circularRegion)
            }
        }
    }
    /// 現在地を取得してからサークルのExitに到達するまでの予測時間
    func calculateArrivalTime() {
        self.speed = self.locationManager.locationManager.location?.speed ?? 0
        // スピードが0以下の場合は到達できないのでnilを返す
        guard self.speed > 0 else { return }
        // Geofenceサークル境界に到達するまでの予測時間(秒)を計算
        let timeToReachBoundaryInSeconds = self.radius / self.speed
        // 現在時刻を取得し、到達する時刻を計算
        let arrivalTime = Date().addingTimeInterval(timeToReachBoundaryInSeconds)
        let formater = DateFormatter()
        formater.dateFormat = "yyyy/MM/dd HH時mm分ss秒"
        formater.locale = Locale(identifier: "ja")
        let formatedDate = formater.string(from: arrivalTime)
    }
}

/// 位置情報取得
public protocol LocationGetable: AnyObject {
    var locationManager: LocationManager { get }
    func didUpdateLocation(_ location: CLLocationCoordinate2D)
    func didFailWithError(_ error: Error)
    func didChangeAuthorizationDenied()
}

public class LocationManager: NSObject {
    let locationManager = CLLocationManager()
    public weak var delegate: LocationGetable?
    public var currentLocation: CLLocationCoordinate2D?
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /// 位置情報のリクエスト
    public func requestLocation() {
        switch self.locationManager.authorizationStatus {
            
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            /// 実装元で設定画面に遷移するダイアログなどを表示する
            self.delegate?.didChangeAuthorizationDenied()
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    /// 権限変更時
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch self.locationManager.authorizationStatus {
        case .restricted, .denied:
            /// 呼び出し元で設定画面に遷移するダイアログなどを表示する
            self.delegate?.didChangeAuthorizationDenied()
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    /// 位置情報取得失敗時
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        /// 呼び出し元で任意の処理を行う
        delegate?.didFailWithError(error)
    }
    /// 位置情報取得成功時
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location.coordinate
            /// 速度(km/h)
            let formateedSpeed = "\(location.speed * 3600 / 1000) km/h"
            /// 速度(m/s)
            let speed = location.speed
            let formater = DateFormatter()
            formater.dateFormat = "yyyy/MM/dd HH時mm分ss秒"
            formater.locale = Locale(identifier: "ja")
            let formatedDate = formater.string(from: Date())
            delegate?.didUpdateLocation(location.coordinate)
            /// TODO：位置情報取得成功時間ログ登録
            locationManager.stopUpdatingLocation() // 一度取得したら停止する場合
        }
    }
    /// GefenceのExit到達時
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let _ = region as? CLCircularRegion {
            /// TODO：Exit到達検知ログ登録
            let formater = DateFormatter()
            formater.dateFormat = "yyyy/MM/dd HH時mm分ss秒"
            formater.locale = Locale(identifier: "ja")
            let formatedDate = formater.string(from: Date())
            /// 位置情報際取得
            self.requestLocation()
        }
    }
}

/// メモ
/*
 位置情報の取得でバックグラウンドも使用する場合
 1. info.plistの設定
 バックグラウンドで位置情報を取得するためには、Info.plistに以下のキーを追加する必要があります。
 NSLocationAlwaysUsageDescription: 常に位置情報を使用する場合の説明。
 NSLocationWhenInUseUsageDescription: アプリ使用中に位置情報を使用する場合の説明。
 NSLocationAlwaysAndWhenInUseUsageDescription: 両方の場合に使用する場合の説明（iOS 11以降）。
 UIBackgroundModes: location を含めることで、バックグラウンドでも位置情報サービスが許可される。
 
 2. CLLocationManagerの設定
 locationManager.allowsBackgroundLocationUpdates = true // バックグラウンドでの更新を許可
 locationManager.pausesLocationUpdatesAutomatically = false // 自動停止を無効にする
 case .notDetermined: locationManager.requestAlwaysAuthorization() // 常に位置情報を取得する権限をリクエスト
 
 3. 位置情報取得の頻度調整
 バックグラウンドでの位置情報取得が高頻度で行われると、バッテリーの消耗が激しくなります。そのため、必要に応じて位置情報取得の精度や頻度を調整することが推奨されます。
 desiredAccuracy: 取得精度を設定します。kCLLocationAccuracyBestは最も高い精度ですが、バッテリー消費も大きくなります。バックグラウンドではkCLLocationAccuracyHundredMetersなど、適度な精度を選ぶのが一般的です。
 distanceFilter: 更新間隔（移動距離）を設定します。これにより、位置情報の更新頻度を制御できます。たとえば、distanceFilter = 100に設定すると、100メートル移動するごとに位置情報が更新されます。
 */
