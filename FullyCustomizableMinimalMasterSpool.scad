// part to be rendered
part = "spoke";   // ["hub":hub,"spoke":spoke,"spokelabel":spoke with label plate,"labelclip":label clip,"testspoke":spoke test element,"testhub":hub test element,"testfilamenthole":filament test hole]

// radius of the axle hole
axleradius  = 20;       // [10:42]

// outer radius of the spool, the minimum MasterSpool specs are 190 mm/2 = 95 mm
spoolradius = 100;    // [95:120]

// number of spokes
numspokes = 3;  // [3,4,5]

// standoffs for problematic spool holders which tend to catch on your MasterSpool. you can print some and don't use them by mounting them to the inside. set to zero to disable
hubstandoffs = 3;

// size of the filament holes, 2 is good for 1.75 mm filament - depending on your print settings
filamentholesize = 2;

// play between assembled parts for best friction fit, depends on your printer setup
play = 0.025;

// resolution higher: more details but more CPU - use 50 for rendering
facets = 15;

// width of the label plate
labelwidth = 94;

// height of the label plate
labelheight = 34;

// orientation of the spoke label (not the clip version)
labelorientation = "horizontal";    // ["horizontal":horizontal,"vertical":vertical]

// dimension of structural elements
structure = 9;  // [7:15]

/* [Hidden] */

// MasterSpool inner radius of the naked filament spool - do not modify
innerradius = 103/2;
// MasterSpool outer radius of the naked filament spool - do not modify
outerradius = 190/2;
// MasterSpool width of the naked filament spool - do not modify
width       = 46;

// radius of the spokes
spokecornerradius = 2;

// thickness of the label plate
labelthickness = 2.2;

// corner radius of the label plate
labelcornerradius = labelthickness * 1/3;

/* end of settings */

use <MCAD/boxes.scad>

$fn=facets;

dovetail = structure/4;

// todo rename to radius
hubdiam = innerradius;
hubwidth = structure;

spokeangles = [for (i=[0:numspokes-1]) i * 360/numspokes];
openingangle = 360/numspokes - 2*15;//3/4 * 360/numspokes;

module makehub()
{
    difference() {
        cylinder(h=hubwidth, r=hubdiam, center=true);
        cylinder(h=2*hubwidth, r=axleradius, center=true);

        // dovetails
        for (a = spokeangles) {
            // filament holes
            rotate([0, 0, a + 360/numspokes/2]) {
                translate([0, -hubdiam+structure/4, 0]) {
                    rotate([90, 0, 0]) {
                        cylinder(h=2*innerradius, r=filamentholesize/2, center=true);
                    }
                }
            }
            
            makehubdovetailrecess(a);
            
            // remove material between spokes
            
            // not clear why I need this differentiation,
            // but I'm currently lacking the time to
            // investigate...
            rangle = (numspokes % 2) == 0 ?
                a + 360/numspokes/2 :
                a + 360/numspokes/2 + 360/numspokes/2;
            rotate([0, 0, rangle]) {
                pie_slice(r=[axleradius+structure/2,
                             hubdiam-structure/2],
                          a=openingangle,
                          h=2*hubwidth);
            }
            
            // remove even more material
            bangle = (numspokes % 2) == 0 ?
                a  :
                a  + 360/numspokes/2;
            rotate([0, 0, bangle]) {
                pie_slice(r=[axleradius+structure/2,
                             hubdiam-structure/2-structure],
                          // please forgive me for the hardcoded 15
                          a=360/numspokes - openingangle - 15,
                          h=2*hubwidth);
            }
        }
    }
    
    // standoffs
    translate([0, 0, hubwidth/2+hubstandoffs/2]) {
        difference() {
            cylinder(h=hubstandoffs, r=axleradius+structure/2, center=true);
            cylinder(h=2*hubstandoffs, r=axleradius, center=true);
        }
    }
}

// TODO: works only for angles <= 90 deg.
module pie_slice(r, a, h) {
    rotate([0, 0, -a/2 + 90]) {
        linear_extrude(height=h, center=true) {
            difference() {
                intersection() {
                    circle(r=r[1]);
                    square(r[1]);
                    rotate(a-90) square(r[1]);
                }
                circle(r=r[0]);
            }
        }
    }
}

module filamenthole(pos) {
    translate([0, 0, pos]) {
        rotate([90, 0, 90]) {
            cylinder(h = 2*structure, r=filamentholesize /2, center=true);
        }
    }
}
module makespoke(withlabel=false)
{
    spokelen = spoolradius - innerradius + structure;

    // make dove tail which locks into hub
    makespokedovetail(width+2*structure);
        
    module makespokeside() {
        translate([0, -spokelen/2 - structure+spokecornerradius, width/2+structure/2]) {
            rotate([90, 0, 0]) {
                difference() {
                    roundedBox(size=[structure,
                                     structure,
                                     spokelen+spokecornerradius],
                               radius=spokecornerradius,
                               sidesonly=false);
                    // filament holes

                    filamenthole(spokelen/2 - structure/2);
                    filamenthole(spokelen/2 - structure/2 - 10);
                    if (spoolradius - outerradius > structure) {
                        filamenthole(spokelen/2 - (spoolradius - outerradius));
                    }
                }
            }
        }
        
        // add stops for hub to sit on
        stopdx = structure * 2;
        stopdy = structure * 4/5;
        stopdz = structure/2;
        translate([0, -stopdy/2, width/2-stopdz + stopdz/2]) {
            roundedBox([stopdx, stopdy, stopdz], radius=stopdz/3);
        }
    }
    
    makespokeside();
    mirror([0, 0, 1]) {
        makespokeside();
    }
    
    if (withlabel) {
        tl = labelorientation == "horizontal" ?
            [0, -labelheight/2 - structure, width/2+structure-labelthickness/2] :
        [0, -labelwidth/2 - structure, width/2+structure-labelthickness/2] ;
        
        translate(tl) {
            rot = labelorientation == "horizontal" ?
                [0, 0, 90] :
                [0, 0,  0] ;

            rotate(rot) {
                roundedBox(size=[labelheight, labelwidth, labelthickness],
                           radius=labelcornerradius,
                           sidesonly=false);
            }
        }
    }
}

module makelabelclip()
{
    roundedBox(size=[labelheight, labelwidth, labelthickness],
               radius=labelcornerradius,
               sidesonly=false);
    
    translate([-labelheight/4, 0, -(structure/2 + labelthickness/2)]) {
        difference() {
            a = 2*labelthickness + structure;
            roundedBox([labelheight/2, a, a],
                       radius=spokecornerradius);
            roundedBox([labelheight/2 + 2*labelthickness, structure, structure],
                       radius=spokecornerradius);

            translate([0, 0, labelthickness+.5]) {
                difference() {
                    roundedBox([2*labelheight,
                                structure+5*labelthickness,
                                structure+5*labelthickness],
                               radius=spokecornerradius);
                    roundedBox([2*labelheight+2*labelthickness,
                                structure+2*labelthickness,
                                structure+2*labelthickness],
                               radius=spokecornerradius);
                }
            }
        }
    }
}

module makespokedovetail(length)
{
    makedovetail(structure + 2*dovetail, structure, structure, length);
}

module makehubdovetailrecess(angle)
{
    factor = (structure+2*play)/structure;

    rotate([0, 0, angle]) {
        translate([0, -hubdiam + structure - 2 * play, 0]) {
            scale([factor, factor, 1]) {
                makedovetail(structure + 2*dovetail,
                             structure,
                             structure, 
                             hubdiam);
            }
        }
    }
}

module makedovetail(a, b, y, length)
{
    linear_extrude(height=length, center=true) {
        polygon([[-a/2,  0],
                 [-b/2, -y],
                 [ b/2, -y],
                 [ a/2,  0]
                ]);
    }
}

module maketesthub()
{
    difference() {
        testwidth = 2.5 * structure;
        testlen = 2 * structure;
        translate([-testwidth/2, -hubdiam, 0]) {
            cube([testwidth, testlen, structure]);
        }
        makehubdovetailrecess(0);
    }
}

module maketestspoke()
{
    makespokedovetail(3*structure);
}

module maketestfilamenthole()
{
    difference() {
        roundedBox([structure, structure, 1.5 * structure],
                   radius=spokecornerradius,
                   sidesonly=true);
        rotate([90, 0, 0]) {
            cylinder(h=2*structure,
                     r=filamentholesize/2,
                     center=true);
        }
    }
}

module renderpart()
{
    pr = [-90, 0, 0];

    if (part == "hub") {
        makehub();
    } else if (part == "spoke") {
        rotate(pr) {
            makespoke();
        }
    } else if (part == "spokelabel") {
        rotate(pr) {
            makespoke(true);
        }
    } else if (part == "labelclip") {
        rotate([0, -90, 0]) {
            makelabelclip();
        }
    } else if (part == "testspoke") {
        rotate(pr) {
            maketestspoke();
        }
    } else if (part == "testhub") {
        maketesthub();
    } else if (part == "testfilamenthole") {
        maketestfilamenthole();
    }    
}

renderpart();