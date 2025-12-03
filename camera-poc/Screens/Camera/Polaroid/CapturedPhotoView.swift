import SwiftUI

struct CapturedPhotoView: View {
    let image: UIImage
    let onClose: () -> Void
    
    var body: some View {
        PolaroidRevealView(image: image, onClose: onClose)
    }
}

