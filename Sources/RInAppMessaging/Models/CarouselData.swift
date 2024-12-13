import UIKit

struct CarouselData {
    var image: UIImage?
    var altText: String?
    var link: String?
}

class CarouselModelHandler {
    private var imageDataList: [CarouselData]
    
    init(data: [String: ImageDetails], images: [UIImage?]) {
        let sortedKeys = (0...4).map { String($0) }
        
        var tempImageDataList: [CarouselData] = []
        
        for (index, key) in sortedKeys.enumerated() {
            if index < images.count {
                let image = images[index]
                let altText = data[key]?.altText
                let link = data[key]?.link
                tempImageDataList.append(CarouselData(image: image, altText: altText, link: link))
            } else {
                tempImageDataList.append(CarouselData(image: nil, altText: nil, link: nil))
            }
        }
        self.imageDataList = tempImageDataList
    }

    func getImageDataList() -> [CarouselData] {
        return imageDataList
    }
}
