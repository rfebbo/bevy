#define_import_path bevy_pbr::ssao_utils

#import bevy_render::maths::{PI, HALF_PI}

// Approximates single-bounce ambient occlusion to multi-bounce ambient occlusion
// https://blog.selfshadow.com/publications/s2016-shading-course/activision/s2016_pbs_activision_occlusion.pdf#page=78
fn ssao_multibounce(visibility: f32, base_color: vec3<f32>) -> vec3<f32> {
    let a = 2.0404 * base_color - 0.3324;
    let b = -4.7951 * base_color + 0.6417;
    let c = 2.7552 * base_color + 0.6903;
    let x = vec3<f32>(visibility);
    return max(x, ((x * a + b) * x + c) * x);
}

// place-99: **specular occlusion from the bent normal**, as cones (Jimenez et al. 2016, "Practical Real-Time Strategies
// for Accurate Indirect Occlusion"; the form is Filament's `specularAO_cones`). The light that is not occluded comes
// from a cone about the bent normal whose solid angle is the visibility's; the reflection gathers from a cone about the
// reflected direction whose width is the roughness's. What reaches the reflection is their intersection over the
// reflection's cone. Where the AO alone (the Lagarde form it replaces) dims a whole glossy face in a corner, this dims
// only the part of the reflection that looks into the corner.

// The solid angle (over 2 PI) where two caps meet, given their half-angles' cosines and the cosine between their axes
// (Oat and Sander 2007, smoothed).
fn spherical_caps_intersection(cos_cap1: f32, cos_cap2: f32, cos_distance: f32) -> f32 {
    let r1 = acos(clamp(cos_cap1, -1.0, 1.0));
    let r2 = acos(clamp(cos_cap2, -1.0, 1.0));
    let d = acos(clamp(cos_distance, -1.0, 1.0));
    if (min(r1, r2) <= max(r1, r2) - d) {
        return 1.0 - max(cos_cap1, cos_cap2);
    } else if (r1 + r2 <= d) {
        return 0.0;
    }
    let delta = abs(r1 - r2);
    let x = 1.0 - saturate((d - delta) / max(r1 + r2 - delta, 0.0001));
    let area = x * x * (-2.0 * x + 3.0);
    return area * (1.0 - max(cos_cap1, cos_cap2));
}

// `visibility` and `bent_normal` (world) from the AO texture, `R` the reflected view direction, `roughness` the
// squared perceptual roughness. A mirror-smooth face is left unoccluded (its cone is a line, and the estimate noise).
fn specular_occlusion_cones(visibility: f32, bent_normal: vec3<f32>, R: vec3<f32>, roughness: f32) -> f32 {
    let cos_av = sqrt(saturate(1.0 - visibility));
    let cos_as = exp2(-3.321928 * roughness * roughness);
    let cos_b = dot(bent_normal, R);
    let ao = spherical_caps_intersection(cos_av, cos_as, cos_b) / max(1.0 - cos_as, 0.0001);
    return mix(1.0, saturate(ao), smoothstep(0.01, 0.09, roughness));
}

