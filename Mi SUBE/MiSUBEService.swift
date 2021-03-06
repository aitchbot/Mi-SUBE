//
//  MiSUBEService.swift
//  Mi SUBE
//
//  Created by Mariano Molina on 26/5/16.
//  Copyright © 2016 Hernan Matias Coppola. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class MiSUBEService {
    
    var mFiltro: Filtro!
    
    func generarURLValida(_ url: String) -> String {
        return url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    }
    
    
    func obtenerPuntosPOST(_ dondeEstoy: MiUbicacion, callback: @escaping ([PuntoCarga]?) -> () ) {
        
        let parameters = [
            "session": "1390472",
            "params": [
                "lat": "\(dondeEstoy.latitude)",
                "lng": "\(dondeEstoy.longitude)"
            ]
        ] as [String : Any]
        

        Alamofire.request(self.generarURLValida("http://dondecargolasube.com.ar/core/?query=getNearPoints"), method: .post, parameters: parameters)
         .validate()
         .responseJSON { response in
             switch response.result {
                case .success:
                    print("Validation Successful")
                
                    if let value = response.result.value {
                        let json = JSON(value)
                        DispatchQueue.main.async {
                            callback(self.jsonParser(json))
                        }
                    }
                
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        callback(nil)
                    }
             }
         }
    }
    
    fileprivate func jsonParser(_ json: JSON) -> [PuntoCarga] {
        
        var listadoPuntos = [PuntoCarga]()
        
        for (_, subJson):(String, JSON) in json {
            
            let pointID = "\(subJson["id"])"
            let adressPoint = "\(subJson["address"])"
            let lat = "\(subJson["latitude"])"
            let lng = "\(subJson["longitude"])"
            let typePoint = "\(subJson["type"])"
            let iconPoint = "\(subJson["icon"])"
            let hourOpen = "\(subJson["hopen"])"
            let hourClose = "\(subJson["hclose"])"
            let costoCarga = "\(subJson["cost"])"
            let fSeller = "\(subJson["flag_seller"])"
            
            
            //Cargo el punto
            let nuevoPunto = PuntoCarga(idPunto: Int(pointID)!, address: adressPoint.htmlDecoded(), latitude: Double(lat)!, longitude: Double(lng)!, type: typePoint, icon: iconPoint, cost: Int(costoCarga)!, hourOpen: Int(hourOpen)!, hourClose: Int(hourClose)!, flagSeller: Int(fSeller)!)
            
            if aplicarFiltro(nuevoPunto) {
                listadoPuntos.append(nuevoPunto)
            }
            
        }
        
        return listadoPuntos
    }
    
    
    
    func aplicarFiltro(_ miPunto: PuntoCarga) -> Bool {
        
        if mFiltro.ocultarCerrados {
            if miPunto.estaAbierto() == EstadoNegocio.cerrado {
                return false
            }
        }
        
        if mFiltro.ocultarCobraCarga {
            if miPunto.cobraPorCargar() == true {
                return false
            }
        }
        
        if mFiltro.ocultarNoVendeSUBE {
            if miPunto.vendeSube() == false {
                return false
            }
        }
        if mFiltro.ocutarHorarioSinIndicar {
            if miPunto.estaAbierto() == EstadoNegocio.indeterminado {
                return false
            }
        }
        return true
    }

    
}
