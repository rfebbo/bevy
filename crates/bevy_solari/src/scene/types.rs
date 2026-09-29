use bevy_asset::Handle;
use bevy_derive::{Deref, DerefMut};
use bevy_ecs::{component::Component, prelude::ReflectComponent, template::FromTemplate};
use bevy_mesh::Mesh;
use bevy_pbr::{MeshMaterial3d, StandardMaterial};
use bevy_reflect::{prelude::ReflectDefault, Reflect};
use bevy_render::sync_world::SyncToRenderWorld;
use bevy_transform::components::Transform;
use derive_more::derive::From;

/// A mesh component used for raytracing.
///
/// The mesh used in this component must have [`Mesh::enable_raytracing`] set to true,
/// use the following set of vertex attributes: `{POSITION, NORMAL, UV_0, TANGENT}`, use [`bevy_mesh::PrimitiveTopology::TriangleList`],
/// and use [`bevy_mesh::Indices::U32`].
///
/// The material used for this entity must be [`MeshMaterial3d<StandardMaterial>`].
#[derive(
    Component, FromTemplate, Clone, Debug, Default, Deref, DerefMut, Reflect, PartialEq, Eq, From,
)]
#[reflect(Component, Default, Clone, PartialEq)]
#[require(MeshMaterial3d<StandardMaterial>, Transform, SyncToRenderWorld)]
pub struct RaytracingMesh3d(pub Handle<Mesh>);

/// The sky's light, for rays that leave the scene.
///
/// Without it a ray that hits nothing brings back nothing, and only the directional lights and
/// emissive meshes light the scene: shade under a roof or a tree is lit by bounce light alone. With
/// it, diffuse and specular indirect rays that escape return this radiance — zenith overhead, horizon
/// at the horizon, `ground` below it — and the sky comes through every gap it can reach.
///
/// Radiance, in the same units as emissive (a uniform sky of radiance `L` puts `π L` on level ground).
/// Absent, or black, is the upstream behaviour.
#[derive(bevy_ecs::resource::Resource, Clone, Copy, Debug, Reflect)]
#[reflect(Default, Clone)]
pub struct SolariSky {
    pub zenith: bevy_color::LinearRgba,
    pub horizon: bevy_color::LinearRgba,
    pub ground: bevy_color::LinearRgba,
}

impl Default for SolariSky {
    /// Black: no sky (`LinearRgba`'s own default is white).
    fn default() -> Self {
        Self {
            zenith: bevy_color::LinearRgba::BLACK,
            horizon: bevy_color::LinearRgba::BLACK,
            ground: bevy_color::LinearRgba::BLACK,
        }
    }
}

impl bevy_render::extract_resource::ExtractResource for SolariSky {
    type Source = SolariSky;

    fn extract_resource(source: &Self::Source) -> Self {
        *source
    }
}
