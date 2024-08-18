import SwiftUI
import MapKit

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            Button {
                if let url = LogManager.shared.getLogFileURL() {
                    print("ログファイルのURL:",url)
                }
            } label: {
                Label(
                    title: { Text("保存") },
                    icon: { Image(uiImage: .checkmark) }
                )
            }

            Map(interactionModes: .all) {
                UserAnnotation()
                MapCircle(
                    center: viewModel.currentLocation,
                    radius: CLLocationDistance(
                        viewModel.radius
                    )
                ).foregroundStyle(Color.blue.opacity(0.3))
            }
            .mapControls {
                MapUserLocationButton()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
