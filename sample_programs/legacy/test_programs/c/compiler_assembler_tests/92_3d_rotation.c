// 92_3d_rotation.c
#include <stdio.h>
#include <math.h>
typedef struct { float x, y, z; } Vec3;
Vec3 rotate_x(Vec3 p, float theta) {
    float c=cos(theta),s=sin(theta);
    return (Vec3){p.x, c*p.y-s*p.z, s*p.y+c*p.z};
}
Vec3 rotate_y(Vec3 p, float theta) {
    float c=cos(theta),s=sin(theta);
    return (Vec3){c*p.x+s*p.z, p.y, -s*p.x+c*p.z};
}
Vec3 rotate_z(Vec3 p, float theta) {
    float c=cos(theta),s=sin(theta);
    return (Vec3){c*p.x-s*p.y, s*p.x+c*p.y, p.z};
}
int main() {
    Vec3 p = {1,2,3};
    float t = 3.14159/4;
    Vec3 rx = rotate_x(p,t), ry = rotate_y(p,t), rz = rotate_z(p,t);
    printf("Rotate X: %.2f %.2f %.2f\n", rx.x,rx.y,rx.z);
    printf("Rotate Y: %.2f %.2f %.2f\n", ry.x,ry.y,ry.z);
    printf("Rotate Z: %.2f %.2f %.2f\n", rz.x,rz.y,rz.z);
    return 0;
}
