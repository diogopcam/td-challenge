import SwiftUI

struct CapturedPhotoView: View {
    let image: UIImage
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Polaroid3DView(image: image)
                .edgesIgnoringSafeArea(.all)
                .background(Color.clear)

            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
