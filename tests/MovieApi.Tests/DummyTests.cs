namespace MovieApi.Tests;

public class DummyTests
{
    [Fact]
    public void Fail()
    {
        Assert.Fail("By design");
    }

    [Fact]
    public void Pass()
    {
        Assert.True(true);
    }
}
