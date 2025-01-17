
import Foundation

enum DiffFetcherError: Error {
    case failureParsingRevisions
    case failureParsingWikitext
}

class DiffFetcher: Fetcher {
    
    enum SingleRevisionRequestDirection: String {
        case older
        case newer
    }
    
    func fetchDiff(fromRevisionId: Int, toRevisionId: Int, siteURL: URL, completion: @escaping ((Result<DiffResponse, Error>) -> Void)) {
        
        guard let url = compareURL(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, siteURL: siteURL) else {
            completion(.failure(DiffError.generateUrlFailure))
            return
        }
        
        session.jsonDecodableTask(with: url) { (result: DiffResponse?, urlResponse: URLResponse?, error: Error?) in
            
            guard let result = result else {
                completion(.failure(DiffError.missingDiffResponseFailure))
                return
            }
            
            guard let _ = urlResponse else {
                completion(.failure(DiffError.missingUrlResponseFailure))
                return
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(result))
        }
    }
    
    func fetchWikitext(siteURL: URL, revisionId: Int, completion: @escaping (Result<String, Error>) -> Void) {
        
        let params: [String: Any] = [
            "action": "query",
            "prop": "revisions",
            "revids": "\(revisionId)",
            "rvprop": "content",
            "format": "json"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { (result, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let query = result?["query"] as? [String: AnyObject],
                let pages = query["pages"] as? [String: AnyObject] else {
                completion(.failure(DiffFetcherError.failureParsingWikitext))
                return
            }
            
            var maybeResult: String?
            for (_, value) in pages {
                guard let valueDict = value as? [String: AnyObject] else {
                    continue
                }
                
                if let revisionsArray = valueDict["revisions"] as? [[String: AnyObject]],
                    revisionsArray.count > 0 {
                    
                    for revision in revisionsArray {
                        
                        if let text = revision["*"] as? String {
                            maybeResult = text
                            break
                        }
                            
                    }
                }
            }
            
            guard let result = maybeResult else {
                completion(.failure(DiffFetcherError.failureParsingWikitext))
                return
            }
            
            completion(.success(result))
        }
    }
    
    private func compareURL(fromRevisionId: Int, toRevisionId: Int, siteURL: URL) -> URL? {
        
        guard let host = siteURL.host else {
            return nil
        }

        var pathComponents = ["v1", "revision"]
        pathComponents.append("\(fromRevisionId)")
        pathComponents.append("compare")
        pathComponents.append("\(toRevisionId)")
        let components = configuration.mediaWikiRestAPIURLForHost(host, appending: pathComponents)
        return components.url
    }
    
    func fetchSingleRevisionInfo(_ siteURL: URL, sourceRevision: WMFPageHistoryRevision, title: String, direction: SingleRevisionRequestDirection, completion: @escaping ((Result<WMFPageHistoryRevision, Error>) -> Void)) -> Void {
        let parameters: [String: Any] = [
            "action": "query",
            "prop": "revisions",
            "rvprop": "ids|timestamp|user|size|parsedcomment|flags",
            "rvlimit": 2,
            "rvdir": direction.rawValue,
            "titles": title,
            "rvstartid": sourceRevision.revisionID,
            "format": "json"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: parameters, cancellationKey: nil) { (result, response, error) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let query = result?["query"] as? [String : Any],
                let pages = query["pages"] as? [String : Any] else {
                    completion(.failure(DiffFetcherError.failureParsingRevisions))
                    return
            }
            
            for (_, value) in pages {
                
                guard let value = value as? [String: Any] else {
                    completion(.failure(DiffFetcherError.failureParsingRevisions))
                    return
                }
                
                let transformer = MTLJSONAdapter.arrayTransformer(withModelClass: WMFPageHistoryRevision.self)
                
                guard let val = value["revisions"],
                    let revisions = transformer?.transformedValue(val) as? [WMFPageHistoryRevision] else {
                    completion(.failure(DiffFetcherError.failureParsingRevisions))
                    return
                }
                
                let filteredRevisions = revisions.filter { $0.revisionID != sourceRevision.revisionID }
                guard let singleRevision = filteredRevisions.first else {
                                                                completion(.failure(DiffFetcherError.failureParsingRevisions))
                                                                return
                }
                
                completion(.success(singleRevision))
                return
            }
            
            completion(.failure(DiffFetcherError.failureParsingRevisions))
        }
    }
}
