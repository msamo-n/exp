# from pkgB import pkgB
from tnc.pkgC import pkgC
from tnc.pkgB import pkgB


def main():
    pkgB()
    pkgC()
    print("Hello from pkga! 4")


if __name__ == "__main__":
    main()
