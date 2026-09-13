#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>
#include "arithmetic/adder.hpp"

TEST_CASE("Adder constructor", "[adder][unit]")
{
    Adder adder;

    REQUIRE(adder.getInputSize() == 6);
    REQUIRE(adder.getOutputSize() == 4);
    REQUIRE(adder.getType() == ComponentTypes::ADDER);
}

TEST_CASE("Adder resize", "[adder][unit]")
{
    Adder adder;

    adder.resizeInputs(8);

    REQUIRE(adder.getInputSize() == 8);
    REQUIRE(adder.getOutputSize() == 5);

    REQUIRE_THROWS(adder.resizeInputs(7));
    REQUIRE_THROWS(adder.resizeOutputs(5));
}

TEST_CASE("Adder propagates invalid input states", "[adder][state][unit]")
{
    SECTION("ERROR has priority")
    {
        Adder adder;

        adder.setInput(0, Signal::State::ERROR);
        adder.notifyStateChanged();

        for (size_t i = 0; i < adder.getOutputSize(); i++)
            REQUIRE(adder.getOutput(i).getState() == Signal::State::ERROR);
    }

    SECTION("UNDEFINED input produces UNDEFINED output")
    {
        Adder adder;

        adder.setInput(0, Signal::State::FALSE);
        adder.notifyStateChanged();

        for (size_t i = 0; i < adder.getOutputSize(); i++)
            REQUIRE(adder.getOutput(i).getState() == Signal::State::UNDEFINED);
    }
}

TEST_CASE("Adder performs signed addition", "[adder][addition][unit]")
{
    SECTION("2 + 1 = 3")
    {
        Adder adder;

        adder.setInput(0, Signal::State::FALSE);
        adder.setInput(1, Signal::State::TRUE);
        adder.setInput(2, Signal::State::FALSE);

        adder.setInput(3, Signal::State::FALSE);
        adder.setInput(4, Signal::State::FALSE);
        adder.setInput(5, Signal::State::TRUE);

        adder.notifyStateChanged();

        REQUIRE(adder.getOutput(0).getState() == Signal::State::FALSE);
        REQUIRE(adder.getOutput(1).getState() == Signal::State::FALSE);
        REQUIRE(adder.getOutput(2).getState() == Signal::State::TRUE);
        REQUIRE(adder.getOutput(3).getState() == Signal::State::TRUE);
    }

    SECTION("-2 + 1 = -1")
    {
        Adder adder;

        adder.setInput(0, Signal::State::TRUE);
        adder.setInput(1, Signal::State::TRUE);
        adder.setInput(2, Signal::State::FALSE);

        adder.setInput(3, Signal::State::FALSE);
        adder.setInput(4, Signal::State::FALSE);
        adder.setInput(5, Signal::State::TRUE);

        adder.notifyStateChanged();

        REQUIRE(adder.getOutput(0).getState() == Signal::State::TRUE);
        REQUIRE(adder.getOutput(1).getState() == Signal::State::FALSE);
        REQUIRE(adder.getOutput(2).getState() == Signal::State::FALSE);
        REQUIRE(adder.getOutput(3).getState() == Signal::State::TRUE);
    }
}

TEST_CASE("Adder handles cancellation to zero", "[adder][addition][unit]")
{
    Adder adder;

    // 3
    adder.setInput(0, Signal::State::FALSE);
    adder.setInput(1, Signal::State::TRUE);
    adder.setInput(2, Signal::State::TRUE);

    // -3
    adder.setInput(3, Signal::State::TRUE);
    adder.setInput(4, Signal::State::TRUE);
    adder.setInput(5, Signal::State::TRUE);

    adder.notifyStateChanged();

    REQUIRE(adder.getOutput(0).getState() == Signal::State::FALSE);
    REQUIRE(adder.getOutput(1).getState() == Signal::State::FALSE);
    REQUIRE(adder.getOutput(2).getState() == Signal::State::FALSE);
    REQUIRE(adder.getOutput(3).getState() == Signal::State::FALSE);
}

TEST_CASE("Adder works after resizing inputs", "[adder][resize][addition][unit]")
{
    Adder adder;

    adder.resizeInputs(8);

    // 7 = 0 111
    adder.setInput(0, Signal::State::FALSE);
    adder.setInput(1, Signal::State::TRUE);
    adder.setInput(2, Signal::State::TRUE);
    adder.setInput(3, Signal::State::TRUE);

    // 7 = 0 111
    adder.setInput(4, Signal::State::FALSE);
    adder.setInput(5, Signal::State::TRUE);
    adder.setInput(6, Signal::State::TRUE);
    adder.setInput(7, Signal::State::TRUE);

    adder.notifyStateChanged();

    // 14 = 0 1110
    REQUIRE(adder.getOutputSize() == 5);
    REQUIRE(adder.getOutput(0).getState() == Signal::State::FALSE);
    REQUIRE(adder.getOutput(1).getState() == Signal::State::TRUE);
    REQUIRE(adder.getOutput(2).getState() == Signal::State::TRUE);
    REQUIRE(adder.getOutput(3).getState() == Signal::State::TRUE);
    REQUIRE(adder.getOutput(4).getState() == Signal::State::FALSE);
}
