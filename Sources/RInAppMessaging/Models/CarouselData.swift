import UIKit

struct CarouselData {
    var image: UIImage?
    var altText: String?
    var link: String?
}

class CarouselModelHandler {
    private var imageDataList: [CarouselData]
    
    init(data: [String: ImageDetails], images: [UIImage?]) {
        let sortedKeys = Array(data.keys).sorted()
        var tempImageDataList: [CarouselData] = []

        for (index, key) in sortedKeys.enumerated() {
            guard index < images.count else { break }

            let image = images[index]
            let altText = data[key]?.altText
            let link = data[key]?.link

            tempImageDataList.append(CarouselData(image: image, altText: altText, link: link))
        }

        self.imageDataList = tempImageDataList
    }

    func getImageDataList() -> [CarouselData] {
        return imageDataList
    }
}
