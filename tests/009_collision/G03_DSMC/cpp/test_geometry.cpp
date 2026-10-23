// SPDX-License-Identifier: Apache-2.0
#include "test_support.hpp"
#include <array>

namespace test {
void geometry() {
    const std::vector<Real> r{0, 1e-3, 3e-3}, theta{-0.5*pi, 0, 0.25*pi, 1.5*pi}, z{-1e-3, 0, 4e-3};
    CylindricalGrid mesh(r, theta, z, AngularBoundary::periodic, 37);
    require(mesh.cells().size() == 12, "nonuniform grid dimensions");
    long double volume = 0;
    for (std::size_t i = 0; i < 2; ++i) {
        for (std::size_t j = 0; j < 3; ++j) {
            for (std::size_t k = 0; k < 2; ++k) {
                const auto id = 37+(i*3+j)*2+k;
                const auto& cell = mesh.cells()[id-37];
                require(cell.global_id == id, "cell flattening order");
                const auto exact = (r[i+1]*r[i+1]-r[i]*r[i])/2 *
                                   (theta[j+1]-theta[j])*(z[k+1]-z[k]);
                close(cell.volume_m3, exact, 3e-15, 0, "individual cylindrical volume");
                require(mesh.locate({(r[i]+r[i+1])/2, (theta[j]+theta[j+1])/2,
                                     (z[k]+z[k+1])/2}) == id, "cell center lookup");
                volume += cell.volume_m3;
            }
        }
    }
    close(volume, pi*r.back()*r.back()*(z.back()-z.front()), 3e-15, 0, "whole-cylinder volume");
    require(mesh.locate({1e-3, 0, 0}) == 46, "internal faces belong to upper interval");
    require(!mesh.locate({3e-3, 0, 0}), "radial upper face excluded");
    require(!mesh.locate({0, 0, 4e-3}), "axial upper face excluded");
    const auto seam = mesh.locate({0.5e-3, theta.front(), -0.5e-3});
    require(mesh.locate({0.5e-3, theta.back(), -0.5e-3}) == seam, "periodic upper seam");
    require(mesh.locate({0.5e-3, theta.front()-4*pi, -0.5e-3}) == seam, "periodic negative wrapping");
    require(mesh.locate({0, 0.1, -0.5e-3}) == 39, "axis retains prescribed angle");
    CylindricalGrid sector({0, 1}, {0, 0.3, 1}, {0, 1}, AngularBoundary::nonperiodic);
    require(!sector.locate({0.5, 1, 0.5}), "nonperiodic upper face excluded");
    require(!sector.locate({0.5, -0.1, 0.5}), "nonperiodic angle not wrapped");
    rejects([] { CylindricalGrid bad({0, 0}, {0, 1}, {0, 1}, AngularBoundary::nonperiodic); },
            "repeated faces");
    rejects([] { CylindricalGrid bad({-1, 1}, {0, 1}, {0, 1}, AngularBoundary::nonperiodic); },
            "negative radial face");
    rejects([] { CylindricalGrid bad({0, 1}, {0, 1}, {0, 1}, AngularBoundary::periodic); },
            "periodic grid needs full turn");
    rejects([&] { mesh.locate({-1, 0, 0}); }, "negative particle radius");
    rejects([&] { mesh.locate({0, std::numeric_limits<Real>::quiet_NaN(), 0}); }, "nonfinite position");
    rejects([] {
        CylindricalGrid bad({0, 1, 2}, {0, 1}, {0, 1}, AngularBoundary::nonperiodic,
                            std::numeric_limits<CellId>::max());
    }, "cell ID overflow");
    for (Real angle : {0.0, 0.7, pi, -2.4}) {
        const CylindricalVelocity local{21, -43, 87};
        const auto global = to_cartesian_velocity(local, angle);
        close(global.x, 21*std::cos(angle)+43*std::sin(angle), 2e-15, 1e-13, "rotation x");
        close(global.y, 21*std::sin(angle)-43*std::cos(angle), 2e-15, 1e-13, "rotation y");
        const auto restored = to_cylindrical_velocity(global, angle);
        close(restored.vr_mps, local.vr_mps, 2e-15, 1e-13, "radial round trip");
        close(restored.vtheta_mps, local.vtheta_mps, 2e-15, 1e-13, "tangential round trip");
        close(global.z, local.vz_mps, 0, 0, "axial velocity unchanged");
    }
    const auto a = to_cartesian_velocity({100, 0, 0}, 0);
    const auto b = to_cartesian_velocity({100, 0, 0}, pi/2);
    close(norm(a-b), 100*std::sqrt(2.0), 2e-15, 0, "distinct local velocity bases");
}

void random_sampling() {
    RandomStream first(91, 2, 37, 4, 1, 3), second(91, 2, 37, 4, 1, 3);
    for (int i = 0; i < 1000; ++i) {
        require(first.next() == second.next(), "keyed stream replay");
    }
    RandomStream rng(12345);
    for (int i = 0; i < 200000; ++i) {
        const auto closed = rng.uniform(), open = rng.open_uniform();
        require(closed >= 0 && closed < 1, "uniform endpoint convention");
        require(open > 0 && open < 1, "open_uniform endpoint convention");
    }
    constexpr std::size_t samples = 200000;
    for (std::uint64_t n : {1, 3, 7, 17, 1000}) {
        std::vector<std::size_t> frequencies(n);
        for (std::size_t i = 0; i < samples; ++i) {
            const auto selected = rng.index(n);
            require(selected < n, "index bounds");
            ++frequencies[selected];
        }
        const long double probability = 1.0L/n;
        const auto tolerance = 6*std::sqrt(samples*probability*(1-probability));
        for (const auto count : frequencies) {
            close(count, samples*probability, 0, tolerance, "uniform index frequencies");
        }
    }
    const auto large = (std::uint64_t{1} << 63)+1;
    for (int i = 0; i < 1000; ++i) {
        require(rng.index(large) < large, "large rejection-sampling range");
    }
    rejects([&] { rng.index(0); }, "empty random range");
}
} // namespace test
