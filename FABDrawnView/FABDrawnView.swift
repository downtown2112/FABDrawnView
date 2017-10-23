//
//  FABDrawnView.swift
//  FABDrawnView
//
//  Created by fred.a.brown on 10/20/17.
//  Copyright © 2017 Zebrasense. All rights reserved.
//

import Foundation
import UIKit

/// Helper struct 
struct FABGeometryHelper {
    var p1: CGPoint
    var p2: CGPoint
    
    init(_ p1: CGPoint, _ p2: CGPoint) {
        self.p1 = p1
        self.p2 = p2
    }
    
    func angle() -> CGFloat {
        return atan2(p2.y - p1.y, p2.x - p1.x)
    }
    
}


/// Custom view containing an extrusion at the top
@IBDesignable
class FABDrawnView : UIView, NibInstantiable {
    
    static var nibName: String = "FABDrawnView"
    static var nibBundle: Bundle = Bundle.main
    
    /// The radius of the extrusion from the top of the view
    /// Note that if this gets "too large", you'll need to compensate by increasing the y insets
    @IBInspectable
    var thumbRadius: CGFloat = 30
    
    /// The offset of the center point of the extrusion from the top of the view.
    /// Positive values (or 0) will produce a rectangle
    /// Negative values greater than the radius will make the extrusion visible
    /// Setting this to the negative value of the radius will place half the extrusion above the view and half below
    @IBInspectable
    var thumbCircleOffset: CGFloat = 0
    
    /// The fill color for the inside of the drawn view
    @IBInspectable
    var fillColor:UIColor = UIColor.white
    
    /// The color to use for the outline of the drawn view
    @IBInspectable
    var strokeColor:UIColor = UIColor.darkGray
    
    /// The width of the drawn stroke
    @IBInspectable
    var pathStrokeWidth:CGFloat = 1.0
    
    /// The radius to use for the 4 corners of the view. Setting this to 0 will produce a rectangle.
    /// Note: Increasing this value to ridiculous levels will look...bad
    @IBInspectable
    var cornerRadius:CGFloat = 0
    
    /// This is how far down to push the rectangular portion of the view, so that room may be left for the extrusion at the top
    @IBInspectable
    var yOffset:CGFloat = 30
    
    /// This value represents the amount of space to pad the sides of the view before the drawing starts.
    /// For example, as you increase the pathStrokeWidth, you may find the borders clipping along the view boundary.
    /// Increasing the widthInset will allow for the full width of the stroke to be visible
    @IBInspectable
    var widthInset:CGFloat = 1.0
    
    /// This value represents the amount of space to pad the top and both of the view before the drawing starts
    /// For example, as you increase the pathStrokeWidth, you may find the borders clipping along the view boundary.
    /// Increasing the heightInset will allow for the full width of the stroke to be visible
    @IBInspectable
    var heightInset:CGFloat = 1.0
    
    /// This is the offset to use for the center point of the extrusion at the top of the view.
    /// A value of 0 will place the extrusion's X location at width/2
    /// Negative values for circleXOffset will shift that center X position to the left
    /// Positive values for circleXOffset will shift that center Y position to the right
    @IBInspectable
    var circleXOffset:CGFloat = 0.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// Overridden draw method
    override func draw(_ rect: CGRect) {
        

        /*********************************************************
         Set points and boundaries
         *********************************************************/
        let width = self.bounds.width
        let height = self.bounds.height
        
        // protect against goofy numbers
        
        if thumbRadius < 0 {
            thumbRadius = 0
        }
        
        if thumbCircleOffset + thumbRadius < 0 {
            thumbCircleOffset = thumbRadius * -1.0
        }

        let centerThumb                 = CGPoint(x: (width/2) + circleXOffset,
                                                  y: thumbRadius + thumbCircleOffset + heightInset + yOffset)
        

        let insetTopLeftEndOfArc        = CGPoint(x: cornerRadius + widthInset,
                                                  y:yOffset + heightInset)
        
        
        let insetTopRightStartOfArc     = CGPoint(x: width - widthInset - cornerRadius,
                                                  y:yOffset + heightInset)
        
        
        
        let insetBottomRighStartOfArc   = CGPoint(x: width - widthInset,
                                                  y: height - cornerRadius - heightInset)
        
        
        
        let insetBottomLeftStartOfArc   = CGPoint(x: cornerRadius + widthInset,
                                                  y:height - heightInset)
        
        
        let insetTopLeftStartReturnArc  = CGPoint(x:widthInset,
                                                  y:height - cornerRadius - heightInset)
        
        
        let centerTopRightArc           = CGPoint(x: width - cornerRadius - widthInset,
                                                  y: yOffset + cornerRadius + heightInset)
        let centerBottomRightArc        = CGPoint(x:width - cornerRadius - widthInset,
                                                  y: height - cornerRadius - heightInset)
        let centerBottomLeftArc         = CGPoint(x:cornerRadius + widthInset,
                                                  y: height - cornerRadius - heightInset)
        let centerTopLeftArc            = CGPoint(x:cornerRadius + widthInset,
                                                  y: yOffset + cornerRadius + heightInset)
        
        // find the intersection of the extension (circle) and the rectangular box
        // result will be a tuple containing the first and second intersection points
        // in cases where the extrusion is tangent to the rectangular box or where the
        //   the extrusion never intersects with the rectangular box, the tuple will
        //   contain the same points for "first" and "second"
        let intersection = findIntersection(startPoint: insetTopLeftEndOfArc,
                                            endPoint: insetTopRightStartOfArc,
                                            circleCenter: centerThumb,
                                            radius: thumbRadius)
        
        // Need to find the angle in radians corresponding to the intersection points of the extrusion (circle)
        //   and the rectangular box
        // Note that orientation for normal drawing is upside down in draw rect.
        // We'll need to jump through some hoops to make this work
        // The ultimate goal is to grab the startRadians and endRadians
        let firstSegment = FABGeometryHelper(centerThumb, intersection.first)
        let secondSegment = FABGeometryHelper(centerThumb, intersection.second)
        let startAngle = secondSegment.angle()
        let endAngle = firstSegment.angle()
        
        let startPi = Double(startAngle) / Double.pi
        let endPi = Double(endAngle) / Double.pi
        
        let startRadians = CGFloat((1 + abs(startPi)) * Double.pi)
        let endRadians = CGFloat((1 + abs(endPi)) * Double.pi)



        
        #if DEBUG
            print("thumbRadius = \(thumbRadius)")
            print("thumbCircleOffset = \(thumbCircleOffset)")
            print("yOffset = \(yOffset)")
            print("heightInset = \(heightInset)")
            print("Center thumb is \(centerThumb)")
            print("InsetTopLeftEndOfArc = \(insetTopLeftEndOfArc)")
            print("InsetTopRightStartOfArc = \(insetTopRightStartOfArc)")
            print("InsetBottomRightStartOfArc = \(insetBottomRighStartOfArc)")
            print("InsetBottomLeftStartOfArc = \(insetBottomLeftStartOfArc)")
            print("InsetTopLeftStartReturnArc = \(insetTopLeftStartReturnArc)")
            print("Found startAngle is \(startAngle) which is \(startPi)")
            print("Found endAngle is \(endAngle) which is \(endPi)")
            
        #endif

        /*********************************************************
         Start Drawing
         *********************************************************/
        let path = UIBezierPath()
        
        path.move(to: insetTopLeftEndOfArc)

        // don't worry about the extrusion if it is tangent to the rectangular box or if it
        //   does not intersect at all
        if intersection.first.x != intersection.second.x {
            path.addLine(to: intersection.first)

            path.addArc(withCenter: centerThumb,
                radius: thumbRadius,
                startAngle:startRadians,
                endAngle: endRadians,
                clockwise: true) 

        }
  
        
        path.addLine(to: insetTopRightStartOfArc)
        
        if cornerRadius > 0 {
            path.addArc(withCenter: centerTopRightArc,
                radius: cornerRadius,
                startAngle: CGFloat((3 * Double.pi)/2),
                endAngle: CGFloat(0),
                clockwise: true)
        }
        
        path.addLine(to: insetBottomRighStartOfArc)
        
        if cornerRadius > 0 {
            path.addArc(withCenter: centerBottomRightArc,
                radius: cornerRadius,
                startAngle: CGFloat(0),
                endAngle: CGFloat(Double.pi / 2),
                clockwise: true)
        }
        
        path.addLine(to: insetBottomLeftStartOfArc)
        
        if cornerRadius > 0 {
            path.addArc(withCenter: centerBottomLeftArc,
                radius: cornerRadius,
                startAngle: CGFloat((Double.pi / 2)),
                endAngle: CGFloat(Double.pi),
                clockwise: true)
        }
        path.addLine(to: insetTopLeftStartReturnArc)
        
        if cornerRadius > 0 {
            path.addArc(withCenter: centerTopLeftArc,
                radius: cornerRadius,
                startAngle: CGFloat(Double.pi),
                endAngle: CGFloat((3 * Double.pi) / 2),
                clockwise: true)
        }
        
        fillColor.setFill()
        path.fill()
        path.close()
        
        path.lineWidth = pathStrokeWidth
        
        strokeColor.setStroke()
        path.stroke()
    }
    
    /// Returns a tuple containing the first and second intersection points for a line between
    /// two points and a circle. If the circle and the line are tangent, or if the there is no
    /// intersection, then the tuple contains the same point for both "first" and "second"
    /// - Parameter startPoint - the starting point of the line
    /// - Parameter endPoint - the end point of the line
    /// - Parameter circleCenter - the center point of the circle
    /// - Parameter radius - the radius of the circle
    /// - Returns - a tuple containing the first (left-most) and second (right-most) points of intersection
    func findIntersection(startPoint:CGPoint,
                          endPoint:CGPoint,
                          circleCenter:CGPoint,
                          radius:CGFloat) -> (first:CGPoint, second:CGPoint) {
        
        // compute the distance between A and B
        let LAB = sqrt(pow((endPoint.x - startPoint.x), 2) + pow((endPoint.y-startPoint.y), 2))
        
        // compute the direction vector D from A to B
        let Dx = (endPoint.x-startPoint.x)/LAB
        let Dy = (endPoint.y-startPoint.y)/LAB
        
        
        // compute the value t of the closest point to the circle center (Cx, Cy)
        let t = Dx * (circleCenter.x-startPoint.x) + Dy * (circleCenter.y-startPoint.y)
        
        
        // compute the coordinates of the point E on line and closest to C
        let Ex = t * Dx + startPoint.x
        let Ey = t * Dy + startPoint.y
        
        // compute the euclidean distance from E to C
        let LEC = sqrt( pow((Ex-circleCenter.x), 2) + pow((Ey-circleCenter.y), 2) )
        
        // test if the line intersects the circle
        if LEC < radius
        {
            // compute distance from t to circle intersection point
            let dt = sqrt(pow(radius, 2) - pow(LEC, 2))
            
            // compute first intersection point
            let Fx = ((t-dt) * Dx) + startPoint.x
            let Fy = ((t-dt) * Dy) + startPoint.y
            
            print ("First intersection is ( \(Fx), \(Fy))")
            
            // compute second intersection point
            let Gx = ((t+dt) * Dx) + startPoint.x
            let Gy = ((t+dt) * Dy) + startPoint.y
            
            print ("Second intersection is ( \(Gx), \(Gy))")
            
            return (first:CGPoint(x: Fx, y: Fy), second:CGPoint(x:Gx, y:Gy))
        }
        else if LEC == radius {
            // circle is tangent to the line
            return (first:startPoint, second:startPoint)
        }
        else {
           // No intersection
            return (first:startPoint, second:startPoint)
        }
        
    }
}



