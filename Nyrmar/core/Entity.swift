//
//  Entity.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit

struct Entity: Hashable
{
    let id: UUID
    
    init(with existingId: UUID)
    {
        self.id = existingId
    }
    
    init()
    {
        self.id = UUID()
    }
}
