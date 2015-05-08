// OpenSCAD Herringbone Wade's Gears Script
// (c) 2015, Frans-Willem Hardijzer
//
// Thanks to Christopher "ScribbleJ" Jansen for the inspiration and most of the calculations
// Thanks to Greg Frost for the "Involute Gears" script.

include <MCAD/involute_gears.scad> 
include <MCAD/teardrop.scad> 

//Set to 1 to render gears as cylinders instead
debug = 1;

/*
 * PARAMETERS
 */
 
//Copy this from your wade extruder
distance_between_axles = 41.7055;

//Parameters for both gears
gear_height = 10; //Height of the actual gears
teeth_twist = 1; //Twist (how slanted the herringbones are)
chamfer_gradient = 1; //Gradient of the chamfered edges

//Gear 1 is small gear (the one that pops on your stepper)
//Gear 1 (small gear, stepper gear) specific parameters
gear1_teeth = 9;
gear1_base_height = 8;
gear1_shaft_diameter = 5 + 0.4;
gear1_setscrew_diameter = 3 + 0.4;
gear1_setnut_diameter = 5.5 + 0.4; //Width across flats
gear1_setnut_height = 2.4 + 0.2;

//Gear 2 (big gear) specific parameters
gear2_teeth = 47;
gear2_outer_thickness = 5;

gear2_shaft_diameter = 8 + 0.4;
gear2_shaft_height = 14;
gear2_middle_diameter = 25;
gear2_nut_diameter = 13; //No tolerance on this one.
gear2_nut_sunk = 6;


//Distance to overlap things.
epsilon = 0.1;

/*
 * CALCULATIONS
 */
cp = 360*distance_between_axles/(gear1_teeth+gear2_teeth);

//Functions
function gear_radius(number_of_teeth, circular_pitch) = number_of_teeth * circular_pitch / 360;

function gear_outer_radius(number_of_teeth, circular_pitch) = gear_radius(number_of_teeth=number_of_teeth, circular_pitch=circular_pitch) + (circular_pitch/180);

function gear_inner_radius(number_of_teeth, circular_pitch) = gear_radius(number_of_teeth=number_of_teeth, circular_pitch=circular_pitch) - (circular_pitch/180);

module mirrordupe(p) {
    children();
    mirror(p) children();
}

module chamfered_herring_gear(height, chamfer_gradient, teeth_twist, number_of_teeth, circular_pitch) {
    radius = gear_radius(number_of_teeth=number_of_teeth, circular_pitch=circular_pitch);
    outer_radius = gear_outer_radius(number_of_teeth=number_of_teeth, circular_pitch=circular_pitch);
    twist = 360 * teeth_twist / number_of_teeth / 2;

    edge = (outer_radius - radius) / chamfer_gradient;
    intersection() {
        union() {
            if (debug == 1) {
                cylinder(h=height, r=outer_radius);
            } else {
                translate([0,0,height/2])
                    mirrordupe([0,0,1])
                        translate([0,0,-epsilon])
                            gear(
                                twist=twist,
                                number_of_teeth=number_of_teeth,
                                circular_pitch=circular_pitch,
                                gear_thickness = (height/2) + epsilon,
                                rim_thickness = (height/2) + epsilon,
                                hub_thickness = (height/2) + epsilon,
                                bore_diameter=0);
            }
        }
        //Cut edges
        union() {
            cylinder(h=edge + epsilon, r1=radius, r2=outer_radius + epsilon*chamfer_gradient);
            translate([0,0,edge])
                cylinder(h=height-2*edge, r=outer_radius);
            translate([0,0,height-edge-epsilon])
                cylinder(h=edge + epsilon, r2=radius, r1=outer_radius + epsilon*chamfer_gradient);
        }
    }
}

module hole(h,r,$fn=8,rot=0) {
    rotate([0,0,rot * (180/$fn)])
        cylinder(h=h, r=r / cos(180 / $fn), $fn=$fn);
}

module gear1() {
    //Variables
    radius = gear_radius(gear1_teeth, cp);
    inner_radius = gear_inner_radius(gear1_teeth, cp);
    outer_radius = gear_outer_radius(gear1_teeth, cp);
    base_chamfer = (outer_radius - radius) / chamfer_gradient;
    shaft_radius = gear1_shaft_diameter/2;
    setnut_distance = (shaft_radius + radius - gear1_setnut_height)/2;
    
    difference() {
        union() {
            //Actual gear
            chamfered_herring_gear(height = gear_height, chamfer_gradient = chamfer_gradient, teeth_twist=teeth_twist,     number_of_teeth=gear1_teeth, circular_pitch=cp);
            //Base
            translate([0,0,-gear1_base_height]) {
                cylinder(h=gear1_base_height + epsilon, r=inner_radius);
                cylinder(h=gear1_base_height - base_chamfer, r=outer_radius);
                translate([0,0,gear1_base_height - base_chamfer - epsilon]) {
                    intersection() {
                        cylinder(h=base_chamfer + epsilon, r2=radius, r1=outer_radius + chamfer_gradient * epsilon);
                        cylinder(h=base_chamfer + epsilon, r=outer_radius);
                    }
                }
            }
        }
        //Shaft
        translate([0,0,-gear1_base_height - epsilon])
            hole(h=gear_height + gear1_base_height + 2*epsilon, r=shaft_radius, $fn=24);
        //Setscrew shaft
        translate([0,0,-gear1_base_height/2]) {
            rotate([0,-90,0]) {
                hole(h=outer_radius + epsilon, r=gear1_setscrew_diameter/2, $fn=8, rot=1);
                translate([0,0,setnut_distance])
                    hole(h=gear1_setnut_height, r=gear1_setnut_diameter/2, $fn=6);
            }
        }
        //Setscrew insertion cube
        translate([-setnut_distance-gear1_setnut_height,-gear1_setnut_diameter/2,-gear1_base_height-epsilon])
            cube([gear1_setnut_height, gear1_setnut_diameter, gear1_base_height/2 + epsilon]);
        
    }
    
}

module gear2() {
    radius = gear_radius(gear2_teeth, cp);
    inner_radius = gear_inner_radius(gear2_teeth, cp);
    outer_radius = gear_outer_radius(gear2_teeth, cp);
    
    //Outer gear
    difference() {
        chamfered_herring_gear(height = gear_height, chamfer_gradient = chamfer_gradient,teeth_twist=-teeth_twist, number_of_teeth=gear2_teeth, circular_pitch=cp);
        
        translate([0,0,-epsilon])
            cylinder(h=gear_height+ 2*epsilon, r=inner_radius - gear2_outer_thickness);
    }
    //Shaft holder
    difference() {
        union() {
            cylinder(h=gear2_shaft_height, r=gear2_middle_diameter/2);
            intersection() {
                gear2_decoration(outer_radius = inner_radius - gear2_outer_thickness, inner_radius = gear2_middle_diameter/2, max_height = gear2_shaft_height);
                cylinder(h=gear2_shaft_height, r=inner_radius);
            }
        }
        translate([0,0,-epsilon])
            hole(h=gear2_shaft_height + 2*epsilon, r=gear2_shaft_diameter/2, $fn=24);
        translate([0,0,gear2_shaft_height - gear2_nut_sunk])
            hole(h=gear2_nut_sunk + epsilon, r=gear2_nut_diameter/2, $fn=6);
    }
}

module gear2_decoration(outer_radius, inner_radius, max_height) {
    //gear2_decorate_full(outer_radius);
    //gear2_decorate_spokes(outer_radius, 5);
    //gear2_decorate_arcs(inner_radius, outer_radius, 5);
    //gear2_decorate_spiral(inner_radius, outer_radius, 5);
    //gear2_decorate_arrows(inner_radius, outer_radius, 5);
    gear2_decorate_drops(inner_radius, outer_radius);
}

module gear2_decorate_full(outer_radius) {
    cylinder(h=gear_height/4, r=outer_radius + epsilon);
}

module gear2_decorate_spokes(outer_radius, number) {
    for (r=[0:360/number:360])
        rotate([0,0,r])
            rotate([90,0,0])
                cylinder(h=outer_radius + epsilon, r=gear_height/2);
}

module gear2_decorate_arcs(inner_radius, outer_radius, number) {
    height = gear_height/3;
    width = 5;
    inner_diameter = outer_radius - inner_radius;
    outer_diameter = inner_diameter + width*2;
    for (r=[0:360/number:360])
        rotate([0,0,r])
            translate([inner_radius + (inner_diameter/2),0,0])
                difference() {
                    cylinder(h=height, r=outer_diameter/2);
                    translate([0,0,-epsilon])
                        cylinder(h=height + 2*epsilon, r=inner_diameter/2);
                    translate([-outer_diameter/2 - epsilon,0,-epsilon])
                        cube([outer_diameter+2*epsilon,outer_diameter+2*epsilon,height + 2*epsilon]);
                }
}

module gear2_decorate_spiral(inner_radius, outer_radius, number) {
    height = gear_height/3;
    width = 5;
    inner_diameter = outer_radius;
    outer_diameter = inner_diameter + width*2;
    for (r=[0:360/number:360])
        rotate([0,0,r])
            translate([(inner_diameter/2),0,0])
                difference() {
                    cylinder(h=height, r=outer_diameter/2);
                    translate([0,0,-epsilon])
                        cylinder(h=height + 2*epsilon, r=inner_diameter/2);
                    translate([-outer_diameter/2 - epsilon,0,-epsilon])
                        cube([outer_diameter+2*epsilon,outer_diameter+2*epsilon,height + 2*epsilon]);
                }
}

module gear2_decorate_arrows(inner_radius, outer_radius, number) {
    height = gear_height/3;
    width = 10;
    diff = outer_radius-inner_radius;
    inner_size = sqrt((diff*diff)/2);
    outer_size = inner_size + width;
    diagonal_size = sqrt(outer_size*outer_size*2);
    for (r=[0:360/number:360])
        rotate([0,0,r])
            translate([(inner_radius + outer_radius)/2,0,0])
                intersection() {
                    rotate([0,0,45])
                        translate([-outer_size/2,-outer_size/2,0])
                            difference() {
                                cube([outer_size,outer_size,height]);
                                translate([width/2,width/2,-epsilon])
                                    cube([outer_size,outer_size,height+2*epsilon]);
                            }
                }
}

module gear2_decorate_drops(inner_radius, outer_radius) {
    
}

//Small gear (gear 1)
gear1();

//Big gear (gear 2)
translate([distance_between_axles,0,0]) {
    gear2();
}