// RUN: %{ispc} --target=host --nowrap --nostdlib -O2 %s -o %t.o

enum material_type {
  DIFFUSE = 0,
};

struct sphere {
  material_type type;
};

export uniform float render(uniform sphere spheres[]) {
  sphere current_sphere = spheres[0]; // this the offensive line. If I add "uniform" to the type of current_sphere, compilation succeeds.
  return 0.0f;
}
