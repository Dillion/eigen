import Foundation
import Interstellar

/// Network model responsible for fetching the SaleArtworks from the API.
class AuctionSaleArtworksNetworkModel {

    let saleID: String
    var saleArtworks: [SaleArtwork]?

    init(saleID: String) {
        self.saleID = saleID
    }

    func fetchSaleArtworks() -> Signal<[SaleArtwork]> {
        let signal = Signal(saleID)

        // Based on the saleID signal, fetch the SaleArtwork models.
        return signal
            .flatMap(fetchSaleArtworkModels)
            .next { saleArtworks in
                self.saleArtworks = saleArtworks
            }
    }
}


/// Number of sale artworks to fetch at once.
private let PageSize = 10

/// Fetches all the sale artworks associated with the sale.
/// This serves as a trampoline for the actual recursive call.
private func fetchSaleArtworkModels(saleID: String, callback: Result<[SaleArtwork]> -> Void) {
    fetchPage(1, forSaleID: saleID, alreadyFetched: []) { result in
        switch result {
        case .Success(let saleArtworks):
            callback(.Success(saleArtworks))
        case .Error(let error):
            callback(.Error(error))
        }
    }
}

/// Recursively calls itself with page+1 until the count of the returned array is < pageSize.
private func fetchPage(page: Int, forSaleID saleID: String, alreadyFetched: [SaleArtwork], callback: Result<[SaleArtwork]> -> Void) {
    ArtsyAPI.getSaleArtworksWithSale(saleID,
        page: page,
        pageSize: PageSize,
        success: { saleArtworks in
            let totalFetchedSoFar = alreadyFetched + saleArtworks

            if saleArtworks.count < PageSize {
                // We have reached the end of the sale artworks, stop recursing.
                callback(.Success(totalFetchedSoFar))
            } else {
                // There are still more sale artworks, so recurse.
                let nextPage = page + 1
                fetchPage(nextPage, forSaleID: saleID, alreadyFetched: totalFetchedSoFar, callback: callback)
            }
        },
        failure: passOnFailure(callback)
    )
}

