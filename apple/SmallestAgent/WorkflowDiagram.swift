import SwiftUI

struct WorkflowDiagram: View {
    private let names = ["Student / Device", "SwiftUI client", "URLSession", "Node API", "Agent SDK runtime", "Claude API"]
    var body: some View {
        Canvas { context, size in
            let ink = Color(red: 0.08, green: 0.15, blue: 0.28), blue = Color(red: 0.16, green: 0.36, blue: 0.60)
            func text(_ value: String, _ x: Double, _ y: Double, _ font: Double = 18) { context.draw(Text(value).font(.system(size: font)).foregroundColor(ink), at: CGPoint(x: x, y: y), anchor: .topLeading) }
            func line(_ a: CGPoint, _ b: CGPoint, dashed: Bool = false) { var p = Path(); p.move(to: a); p.addLine(to: b); context.stroke(p, with: .color(blue), style: StrokeStyle(lineWidth: 2, dash: dashed ? [7,5] : [])) }
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.97, green: 0.98, blue: 1)))
            text("One prompt through SwiftUI, Node and the Claude Agent SDK", 30, 25, 28)
            text("UML sequence diagram · POST SSE · selected application-level interactions", 30, 65)
            let xs = [140.0,420,700,980,1260,1540]
            for i in 0..<6 {
                let rect = CGRect(x: xs[i]-125, y: 100, width: 250, height: 80)
                context.fill(Path(roundedRect: rect, cornerRadius: 14), with: .color(i % 2 == 0 ? Color(red: 0.91, green: 0.96, blue: 1) : Color(red: 0.95, green: 0.92, blue: 1)))
                context.stroke(Path(roundedRect: rect, cornerRadius: 14), with: .color(blue.opacity(0.3)))
                text(names[i], xs[i]-108, 125, 20)
                line(CGPoint(x: xs[i],y:180), CGPoint(x:xs[i],y:1615), dashed:true)
            }
            for (rect,label) in [(CGRect(x:285,y:650,width:1370,height:280),"loop [streamed SDK messages]"),(CGRect(x:20,y:945,width:1640,height:645),"alt [complete]")] {
                context.stroke(Path(roundedRect:rect,cornerRadius:8),with:.color(blue.opacity(0.5)));text(label,rect.minX+12,rect.minY+10,17)
            }
            for (y,label) in [(1290.0,"[failure]"),(1450.0,"[missing key or invalid input]")] { line(CGPoint(x:20,y:y),CGPoint(x:1660,y:y),dashed:true);text(label,30,y+8,17) }
            for (i,step) in Resources.steps.enumerated() {
                guard xs.indices.contains(step.from), xs.indices.contains(step.to) else { continue }
                let x1=xs[step.from],x2=xs[step.to],y=225.0+Double(i)*82+(i>=6 ? 12:0)+(i>=9 ? 22:0)
                text("\(i+1). \(step.title)",min(x1,x2)+12,y-25,17)
                var p=Path();p.move(to:CGPoint(x:x1,y:y));var end=CGPoint(x:x2,y:y)
                if x1 == x2 { p.addLine(to:CGPoint(x:x1+65,y:y));p.addLine(to:CGPoint(x:x1+65,y:y+30));end=CGPoint(x:x1,y:y+30) }
                p.addLine(to:end);context.stroke(p,with:.color(blue),style:StrokeStyle(lineWidth:2,dash:i>=5 ? [7,5]:[]))
                let direction=x2>x1 ? 1.0 : -1.0;var arrow=Path();arrow.move(to:end);arrow.addLine(to:CGPoint(x:end.x-direction*12,y:end.y-6));arrow.addLine(to:CGPoint(x:end.x-direction*12,y:end.y+6));arrow.closeSubpath();context.fill(arrow,with:.color(blue))
            }
        }.accessibilityLabel("Sixteen-step UML workflow from SwiftUI through URLSession, Node, Agent SDK and Claude API. Source explanations follow the diagram.")
    }
}
