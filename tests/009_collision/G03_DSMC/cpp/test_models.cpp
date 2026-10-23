// SPDX-License-Identifier: Apache-2.0
#include "test_support.hpp"

namespace test {
void models() {
    const Real d = 4e-10, temperature = 300, mass = argon.mass_kg;
    for (const auto type : {ElasticModel::HS, ElasticModel::VHS, ElasticModel::VSS}) {
        const auto p = parameters(type);
        DsmcModel model(argon, 1e10, p);
        for (Real g : {1e-3, 30.0, 500.0, 5000.0}) {
            // 独立写成 Bird 截面乘以 g，检查参考质量、Gamma 规范和幂次。
            const auto expected = pi*d*d*g *
                std::pow(4*boltzmann*temperature/(mass*g*g), p.omega-0.5) /
                std::tgamma(2.5-p.omega);
            close(model.rate().kernel(g), expected, 3e-14, 0, "Bird kernel");
            require(model.rate().kernel(g) <= model.rate().majorant(5000), "interval majorant");
        }
        const auto mu = reference_viscosity(mass, d, temperature, p.omega, p.alpha);
        close(reference_diameter(mass, mu, temperature, p.omega, p.alpha), d, 3e-15, 0,
              "diameter/viscosity round trip");
        close(reference_viscosity(mass, 2*d, temperature, p.omega, p.alpha), mu/4, 3e-15, 0,
              "viscosity diameter scaling");
        close(model.properties().viscosity_ref_pa_s, mu, 0, 0, "reported viscosity");

        // Maxwell 相对速率分布的 Simpson 积分；采样温度为参考温度的两倍。
        const auto speed_scale = std::sqrt(8*boltzmann*temperature/mass);
        long double integral = 0;
        constexpr int intervals = 20000;
        constexpr long double h = 8.0L/intervals;
        for (int i = 0; i <= intervals; ++i) {
            const auto x = i*h;
            const auto density = 4/std::sqrt(pi)*x*x*std::exp(-x*x);
            integral += (i == 0 || i == intervals ? 1 : i % 2 ? 4 : 2) * density *
                        model.rate().kernel(static_cast<Real>(speed_scale*x));
        }
        integral *= h/3;
        const auto expected_mean = 4*d*d*std::sqrt(pi*boltzmann*temperature/mass) *
                                   std::pow(2.0, 1-p.omega);
        close(integral, expected_mean, 2e-9, 0, "Maxwell thermal average");
    }
    const auto hs_mu = 5*std::sqrt(mass*boltzmann*temperature/pi)/(16*d*d);
    close(reference_viscosity(mass, d, temperature), hs_mu, 3e-15, 0, "hard-sphere viscosity");
    HardSphereRate hs(d);
    VhsRate hs_limit(mass, d, temperature, 0.5), maxwell(mass, d, temperature, 1);
    close(hs_limit.kernel(123), hs.kernel(123), 3e-15, 0, "VHS hard-sphere limit");
    close(maxwell.kernel(0), maxwell.kernel(1234), 0, 0, "Maxwell zero-speed extension");
    for (Real bad : {-1.0, 0.0, std::numeric_limits<Real>::infinity(),
                     std::numeric_limits<Real>::quiet_NaN()}) {
        rejects([&] { HardSphereRate invalid(bad); }, "invalid diameter");
        rejects([&] { DsmcModel invalid(argon, bad, parameters(ElasticModel::HS)); }, "invalid weight");
        rejects([&] { reference_viscosity(bad, d, temperature); }, "invalid molecular mass");
        rejects([&] { VhsRate invalid(mass, d, bad, 0.81); }, "invalid reference temperature");
        rejects([&] { reference_diameter(mass, bad, temperature); }, "invalid viscosity");
    }
    auto p = parameters(ElasticModel::HS);
    p.omega = 0.81;
    rejects([&] { DsmcModel invalid(argon, 1, p); }, "HS parameter constraints");
    p = parameters(ElasticModel::VHS);
    p.alpha = 1.4;
    rejects([&] { DsmcModel invalid(argon, 1, p); }, "VHS angle constraint");
    for (Real bad : {0.4, 1.1}) {
        rejects([&] { VhsRate invalid(mass, d, temperature, bad); }, "omega range");
    }
    rejects([] { VssScattering invalid(0.9); }, "alpha range");
    auto charged = argon;
    charged.charge_state = 1;
    rejects([&] { DsmcModel invalid(charged, 1, parameters(ElasticModel::HS)); }, "charged species");
    auto unnamed = argon;
    unnamed.name.clear();
    rejects([&] { DsmcModel invalid(unnamed, 1, parameters(ElasticModel::HS)); }, "empty species name");
    p.type = static_cast<ElasticModel>(99);
    rejects([&] { DsmcModel invalid(argon, 1, p); }, "model enumeration");
    rejects([&] { hs.kernel(-1); }, "negative relative speed");
}

void scattering() {
    constexpr std::size_t samples = 60000;
    const Vec3 incoming{123, -321, 87};
    const Real g = norm(incoming);
    const Vec3 transverse = cross(incoming/g, Vec3{1, 0, 0});
    const Vec3 axis = transverse/norm(transverse);
    for (Real alpha : {1.0, 1.4, 2.5}) {
        VssScattering scatter(alpha);
        RandomStream rng(9182);
        Statistics cosine, square, azimuth;
        std::size_t backwards = 0;
        for (std::size_t i = 0; i < samples; ++i) {
            const auto out = scatter.sample(incoming, rng);
            close(norm(out), g, 3e-15, 0, "elastic relative speed");
            const auto mu = dot(incoming/g, out/g);
            cosine.add(mu);
            square.add(mu*mu);
            azimuth.add(dot(axis, out/g));
            backwards += mu < 0;
        }
        const long double mean = (alpha-1)/(alpha+1);
        const long double second = 1-4*alpha/((alpha+1)*(alpha+2));
        const long double fourth = 16*alpha/(alpha+4)-32*alpha/(alpha+3)+
                                   24*alpha/(alpha+2)-8*alpha/(alpha+1)+1;
        close(cosine.mean, mean, 0, 6*std::sqrt((second-mean*mean)/samples), "mean scattering cosine");
        close(square.mean, second, 0, 6*std::sqrt((fourth-second*second)/samples), "second angular moment");
        close(azimuth.mean, 0, 0, 6*std::sqrt((1-second)/(2*samples)), "azimuth symmetry");
        const auto probability = std::pow(2.0, -alpha);
        close(static_cast<Real>(backwards)/samples, probability, 0,
              6*std::sqrt(probability*(1-probability)/samples), "backward scattering probability");
    }
    IsotropicScattering isotropic;
    VssScattering limit(1);
    RandomStream first(77), second(77);
    for (const Vec3 v : {Vec3{1, 0, 0}, Vec3{0, 1, 0}, Vec3{0, 0, 1},
                         Vec3{1e-15, 0, 1}, Vec3{}}) {
        const auto a = isotropic.sample(v, first), b = limit.sample(v, second);
        require(finite(a), "axis/zero scattering stays finite");
        close(norm(a), norm(v), 3e-15, 0, "axis/zero speed conservation");
        require(a.x == b.x && a.y == b.y && a.z == b.z, "VSS alpha=1 sample agreement");
    }
}
} // namespace test
