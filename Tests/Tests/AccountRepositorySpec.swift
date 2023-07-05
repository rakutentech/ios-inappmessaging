import Quick
import Nimble
@testable import RInAppMessaging

class AccountRepositorySpec: QuickSpec {

    override func spec() {

        describe("AccountRepository") {

            var accountRepository: AccountRepository!

            beforeEach {
                accountRepository = AccountRepository(userDataCache: UserDataCacheMock())
            }

            context("when calling setPreference()") {

                it("will set userInfoProvider object reference") {
                    let userInfoProvider = UserInfoProviderMock()
                    accountRepository.setPreference(userInfoProvider)
                    expect(accountRepository.userInfoProvider).to(beIdenticalTo(userInfoProvider))
                }

                it("will not create a copy of provided UserInfoProvider object") {
                    let userInfoProvider = UserInfoProviderMock()
                    accountRepository.setPreference(userInfoProvider)
                    userInfoProvider.accessToken = "token"
                    userInfoProvider.userID = "user"
                    userInfoProvider.idTrackingIdentifier = "tracking-id"
                    expect(accountRepository.userInfoProvider?.getUserID()).to(equal("user"))
                    expect(accountRepository.userInfoProvider?.getAccessToken()).to(equal("token"))
                    expect(accountRepository.userInfoProvider?.getIDTrackingIdentifier()).to(equal("tracking-id"))
                }
            }

            context("when calling getUserIdentifiers()") {

                it("will return empty array if no preference has been set (nil)") {
                    expect(accountRepository.getUserIdentifiers()).to(beEmpty())
                }

                it("will return identifiers from userInfoProvider object") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.accessToken = "token"
                    userInfoProvider.userID = "user"
                    accountRepository.setPreference(userInfoProvider)
                    expect(accountRepository.getUserIdentifiers()).toNot(beEmpty())
                    expect(accountRepository.getUserIdentifiers()).to(elementsEqual(userInfoProvider.userIdentifiers))
                }
            }

            context("when calling updateUserInfo()") {

                it("will return false if no preference was set") {
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                it("will return true if updateUserInfo() was called for the first time with empty preference") {
                    accountRepository.setPreference(UserInfoProviderMock())
                    expect(accountRepository.updateUserInfo()).to(beTrue())
                }

                it("will return true if updateUserInfo() was called for the first time with non-empty preference") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.userID = "user"
                    accountRepository.setPreference(userInfoProvider)
                    expect(accountRepository.updateUserInfo()).to(beTrue())
                }

                it("will return false if no change was made") {
                    accountRepository.setPreference(UserInfoProviderMock())
                    accountRepository.updateUserInfo() // first call
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                it("will return false if only accessToken was added") {
                    let userInfoProvider = UserInfoProviderMock()
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    userInfoProvider.accessToken = "token"
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                it("will return false if only accessToken was changed") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.userID = "user"
                    userInfoProvider.accessToken = "tokenA"
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    userInfoProvider.accessToken = "tokenB"
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                it("will return true if userID was changed") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.userID = "userA"
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    userInfoProvider.userID = "userB"
                    expect(accountRepository.updateUserInfo()).to(beTrue())
                }

                it("will return false if userID stayed the same") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.userID = "user"
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                it("will return true if idTrackingTdentifier was changed") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.idTrackingIdentifier = "tracking-id-A"
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    userInfoProvider.idTrackingIdentifier = "tracking-id-B"
                    expect(accountRepository.updateUserInfo()).to(beTrue())
                }

                it("will return false if idTrackingTdentifier stayed the same") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.idTrackingIdentifier = "tracking-id"
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                it("will return false if idTrackingTdentifier and userId stayed the same") {
                    let userInfoProvider = UserInfoProviderMock()
                    userInfoProvider.idTrackingIdentifier = "tracking-id"
                    userInfoProvider.userID = "user"
                    accountRepository.setPreference(userInfoProvider)
                    accountRepository.updateUserInfo() // first call
                    expect(accountRepository.updateUserInfo()).to(beFalse())
                }

                context("and UserChangeObserver is registered") {
                    var userChangeObserver: UserChangeObserverSpy!
                    let userInfoProvider = UserInfoProviderMock()

                    beforeEach {
                        userChangeObserver = UserChangeObserverSpy()
                        userInfoProvider.clear()
                        accountRepository.setPreference(userInfoProvider)
                    }

                    it("will not receive an update for the first preference (empty string") {
                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.userID = ""
                        userInfoProvider.idTrackingIdentifier = ""
                        accountRepository.updateUserInfo()

                        expect(userChangeObserver.didReceiveUpdate).to(beFalse())
                    }

                    it("will not receive an update for the first preference (nil)") {
                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        accountRepository.updateUserInfo()

                        expect(userChangeObserver.didReceiveUpdate).to(beFalse())
                    }

                    it("will not receive an update for the first preference (ID values)") {
                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.userID = "user"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        accountRepository.updateUserInfo()

                        expect(userChangeObserver.didReceiveUpdate).to(beFalse())
                    }

                    it("will receive an update if all user IDs change to null (logout)") {
                        userInfoProvider.userID = "user"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        accountRepository.updateUserInfo()

                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.userID = nil
                        userInfoProvider.idTrackingIdentifier = nil
                        accountRepository.updateUserInfo()
                        expect(userChangeObserver.didReceiveUpdate).to(beTrue())
                    }

                    it("will receive an update if all user IDs change to empty string (logout)") {
                        userInfoProvider.userID = "user"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        accountRepository.updateUserInfo()

                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.userID = ""
                        userInfoProvider.idTrackingIdentifier = ""
                        accountRepository.updateUserInfo()
                        expect(userChangeObserver.didReceiveUpdate).to(beTrue())
                    }

                    it("will receive an update if one of user identifiers was cleared (user change)") {
                        userInfoProvider.userID = "user"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        accountRepository.updateUserInfo()

                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.idTrackingIdentifier = nil
                        accountRepository.updateUserInfo()
                        expect(userChangeObserver.didReceiveUpdate).to(beTrue())
                    }

                    it("will receive an update if one of user identifiers was changed (user change)") {
                        userInfoProvider.userID = "userA"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        accountRepository.updateUserInfo()

                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.userID = "userB"
                        accountRepository.updateUserInfo()
                        expect(userChangeObserver.didReceiveUpdate).to(beTrue())
                    }

                    it("will not receive an update if accessToken was added") {
                        userInfoProvider.userID = "userA"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        accountRepository.updateUserInfo()

                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.accessToken = "token"
                        accountRepository.updateUserInfo()
                        expect(userChangeObserver.didReceiveUpdate).to(beFalse())
                    }

                    it("will not receive an update if accessToken was cleared") {
                        userInfoProvider.userID = "userA"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        userInfoProvider.accessToken = "token"
                        accountRepository.updateUserInfo()

                        accountRepository.registerAccountUpdateObserver(userChangeObserver)
                        userInfoProvider.accessToken = nil
                        accountRepository.updateUserInfo()
                        expect(userChangeObserver.didReceiveUpdate).to(beFalse())
                    }
                }

                context("and assertions are checked") {
                    let userInfoProvider = UserInfoProviderMock()
                    beforeEach {
                        userInfoProvider.clear()
                        accountRepository.setPreference(userInfoProvider)
                    }

                    it("will throw an error if accessToken was specified without userId (for Rakuten apps)") {
                        userInfoProvider.accessToken = "access-token"
                        expect(accountRepository.checkAssertions()).to(throwAssertion())
                    }

                    it("will throw an error if accessToken was specified with empty userId (for Rakuten apps)") {
                        userInfoProvider.accessToken = "access-token"
                        userInfoProvider.userID = ""
                        expect(accountRepository.checkAssertions()).to(throwAssertion())
                    }

                    it("will throw an error if accessToken was specified with idTrackingIdentifier (for Rakuten apps)") {
                        // meaning that there's no userId specified
                        userInfoProvider.accessToken = "access-token"
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        expect(accountRepository.checkAssertions()).to(throwAssertion())
                    }

                    it("will not throw an error for empty preference") {
                        expect(accountRepository.checkAssertions()).toNot(throwAssertion())
                    }

                    it("will not throw an error if idTrackingIdentifier is specified and accessToken is empty") {
                        userInfoProvider.accessToken = ""
                        userInfoProvider.idTrackingIdentifier = "tracking-id"
                        expect(accountRepository.checkAssertions()).toNot(throwAssertion())
                    }
                }
            }
        }
    }
}

private class UserChangeObserverSpy: UserChangeObserver {
    var didReceiveUpdate = false

    func userDidChangeOrLogout() {
        didReceiveUpdate = true
    }
}
