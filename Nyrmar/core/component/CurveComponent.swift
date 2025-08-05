//
//  CurveComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//


/// Component defining an interpolation curve for movement
enum CurveType: Hashable
{
    case linear, easeIn, easeOut
}

class CurveComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: CurveComponent.self)
    var siblings: SiblingContainer?
    
    var curveType: CurveType
    
    init(curveType: CurveType)
    {
        self.curveType = curveType
    }
}
