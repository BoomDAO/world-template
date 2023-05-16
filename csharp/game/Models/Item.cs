using offerId = System.String;
using TokenIndex = System.UInt32;
using AccountIdentifier = System.String;
using EdjCase.ICP.Candid.Mapping;

namespace Candid.game.Models
{
	public class Item
	{
		[CandidName("id")]
		public string Id { get; set; }

		[CandidName("quantity")]
		public double Quantity { get; set; }

		public Item(string id, double quantity)
		{
			this.Id = id;
			this.Quantity = quantity;
		}

		public Item()
		{
		}
	}
}