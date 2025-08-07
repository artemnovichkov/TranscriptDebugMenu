import SwiftUI

struct ContentView: View {
    @State private var text = "Loading..."

    var body: some View {
        NavigationStack {
            VStack {
                Text(text)
            }
            .padding(.horizontal)
            .navigationTitle("Haiku")
        }
    }
}
