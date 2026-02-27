// 89_3d_point_projection.c
#include <stdio.h>
typedef struct { float x, y, z; } Vec3;
typedef struct { float x, y; } Vec2;
Vec2 ortho_project(Vec3 p) { return (Vec2){p.x, p.y}; }
Vec2 persp_project(Vec3 p, float d) { return (Vec2){d*p.x/(d+p.z), d*p.y/(d+p.z)}; }
int main() {
    Vec3 pts[] = {{1,2,3},{-2,1,5},{0,0,0},{3,3,3}};
    float d = 5.0;
    for(int i=0;i<4;i++) {
        Vec2 o = ortho_project(pts[i]);
        Vec2 p = persp_project(pts[i], d);
        printf("3D:(%.1f,%.1f,%.1f) Ortho:(%.1f,%.1f) Persp:(%.2f,%.2f)\n", pts[i].x,pts[i].y,pts[i].z, o.x,o.y, p.x,p.y);
    }
    return 0;
}
