// 93_3d_transform.c
#include <stdio.h>
typedef struct { float x, y, z; } Vec3;
Vec3 translate(Vec3 p, float dx, float dy, float dz) { return (Vec3){p.x+dx, p.y+dy, p.z+dz}; }
Vec3 scale(Vec3 p, float sx, float sy, float sz) { return (Vec3){p.x*sx, p.y*sy, p.z*sz}; }
int main() {
    Vec3 p = {1,2,3};
    Vec3 pt = translate(p, 5, -2, 1);
    Vec3 ps = scale(p, 2, 0.5, -1);
    printf("Translate: %.2f %.2f %.2f\n", pt.x,pt.y,pt.z);
    printf("Scale: %.2f %.2f %.2f\n", ps.x,ps.y,ps.z);
    return 0;
}
