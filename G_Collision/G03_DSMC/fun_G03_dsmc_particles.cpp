// SPDX-License-Identifier: Apache-2.0
#include "collision_kernel.hpp"
#include <unordered_set>

namespace algoplasma::dsmc::detail {
void snapshot_particles(std::span<const CylindricalParticleState> particles,
                        const CylindricalGrid& grid, SpeciesId species_id,
                        std::vector<CollisionParticle>& out) {
    out.clear();
    out.reserve(particles.size());
    std::unordered_set<ParticleId> ids;
    ids.reserve(particles.size());
    for (std::size_t i = 0; i < particles.size(); ++i) {
        const auto& particle = particles[i];
        if (!ids.insert(particle.id).second) {
            throw Error("duplicate particle ID");
        }
        if (particle.species_id != species_id) {
            throw Error("unknown particle species");
        }
        const auto cell = grid.locate(particle.position);
        if (!cell) {
            throw Error("particle lies outside the collision grid");
        }
        const auto velocity =
            to_cartesian_velocity(particle.velocity_mps, particle.position.theta_rad);
        out.push_back({particle.id, *cell, velocity, velocity, i});
    }
}

void prepare_particle_velocities(std::span<const CylindricalParticleState> particles,
                                 std::span<const CollisionParticle> snapshot,
                                 std::vector<CylindricalVelocity>& pending) {
    pending.resize(particles.size());
    for (const auto& particle : snapshot) {
        const auto& source = particles[particle.source_index];
        const auto velocity = particle.velocity_mps;
        const auto initial = particle.initial_velocity_mps;
        // 未改变的速度保留原始局部分量，避免零时间步或未碰撞粒子的坐标往返漂移。
        pending[particle.source_index] =
            velocity.x == initial.x && velocity.y == initial.y && velocity.z == initial.z
                ? source.velocity_mps
                : to_cylindrical_velocity(velocity, source.position.theta_rad);
    }
}
} // namespace algoplasma::dsmc::detail
