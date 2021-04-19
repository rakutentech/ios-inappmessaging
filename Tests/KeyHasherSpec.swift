import Quick
import Nimble
@testable import RInAppMessaging

class KeyHasherSpec: QuickSpec {

    override func spec() {
        // Be sure to run those tests for ios version >=13.0 and <13.0
        describe("KeyHasher") {

            var hasher: KeyHasher!

            beforeEach {
                hasher = KeyHasher()
            }

            [KeyHasher.Encryption.md5, KeyHasher.Encryption.sha256].forEach { encryption in
                context("when using \(encryption) encryption method") {

                    beforeEach {
                        hasher.encryprtionMethod = encryption
                    }

                    it("will generate a valid hash for empty data") {
                        expect(hasher.generateHash()).toNot(beEmpty())
                    }

                    it("will generate a valid hash for empty value") {
                        hasher.combine("")
                        expect(hasher.generateHash()).toNot(beEmpty())
                    }

                    it("will generate a valid hash for single added value") {
                        hasher.combine("some value")
                        expect(hasher.generateHash()).toNot(beEmpty())
                    }

                    it("will generate a valid hash for multiple added values") {
                        hasher.combine("some value")
                        hasher.combine("another value")
                        hasher.combine("some other value")
                        expect(hasher.generateHash()).toNot(beEmpty())
                    }

                    it("will generate the same hash for the same values") {
                        hasher.combine("some value")
                        let resultA = hasher.generateHash()

                        var anotherHasher = KeyHasher()
                        anotherHasher.encryprtionMethod = hasher.encryprtionMethod
                        anotherHasher.combine("some value")
                        let resultB = anotherHasher.generateHash()

                        expect(resultA).to(equal(resultB))
                    }

                    it("will generate different hash for different values") {
                        hasher.combine("some value")
                        let resultA = hasher.generateHash()

                        var anotherHasher = KeyHasher()
                        anotherHasher.encryprtionMethod = hasher.encryprtionMethod
                        anotherHasher.combine("another value")
                        let resultB = anotherHasher.generateHash()

                        expect(resultA).toNot(equal(resultB))
                    }

                    context("with added salt") {

                        beforeEach {
                            hasher.salt = "salt"
                        }

                        it("will generate a valid hash for empty data") {
                            expect(hasher.generateHash()).toNot(beEmpty())
                        }

                        it("will generate a valid hash for empty value") {
                            hasher.combine("")
                            expect(hasher.generateHash()).toNot(beEmpty())
                        }

                        it("will generate a valid hash for single added value") {
                            hasher.combine("some value")
                            expect(hasher.generateHash()).toNot(beEmpty())
                        }

                        it("will generate a valid hash for multiple added values") {
                            hasher.combine("some value")
                            hasher.combine("another value")
                            hasher.combine("some other value")
                            expect(hasher.generateHash()).toNot(beEmpty())
                        }

                        it("will generate the same hash for the same values") {
                            hasher.combine("some value")
                            let resultA = hasher.generateHash()

                            var anotherHasher = KeyHasher()
                            anotherHasher.encryprtionMethod = hasher.encryprtionMethod
                            anotherHasher.salt = hasher.salt
                            anotherHasher.combine("some value")
                            let resultB = anotherHasher.generateHash()

                            expect(resultA).to(equal(resultB))
                        }

                        it("will generate different hash for different values") {
                            hasher.combine("some value")
                            let resultA = hasher.generateHash()

                            var anotherHasher = KeyHasher()
                            anotherHasher.encryprtionMethod = hasher.encryprtionMethod
                            anotherHasher.salt = hasher.salt
                            anotherHasher.combine("another value")
                            let resultB = anotherHasher.generateHash()

                            expect(resultA).toNot(equal(resultB))
                        }
                    }
                }
            }
        }
    }
}
