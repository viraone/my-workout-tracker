import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    static let projectURL = URL(
        string: "https://fzzevbrnxlaxzcowpaqz.supabase.co"
    )!

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: Self.projectURL,
            supabaseKey: "sb_publishable_7XA6UknPNNYdRhBsumZhnw_Pkc0F4xw"
        )
    }
}
