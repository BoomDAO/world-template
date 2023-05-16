using offerId = System.String;
using TokenIndex = System.UInt32;
using AccountIdentifier = System.String;
using EdjCase.ICP.Candid.Mapping;
using Candid.game.Models;
using EdjCase.ICP.Candid.Models;
using System.Collections.Generic;

namespace Candid.game.Models
{
	public class CoreTxData
	{
		[CandidName("bought_offers")]
		public OptionalValue<CoreTxData.BoughtOffersItemRecord> BoughtOffers { get; set; }

		[CandidName("items")]
		public OptionalValue<CoreTxData.ItemsItemRecord> Items { get; set; }

		[CandidName("profile")]
		public OptionalValue<Profile> Profile { get; set; }

		public CoreTxData(OptionalValue<CoreTxData.BoughtOffersItemRecord> boughtOffers, OptionalValue<CoreTxData.ItemsItemRecord> items, OptionalValue<Profile> profile)
		{
			this.BoughtOffers = boughtOffers;
			this.Items = items;
			this.Profile = profile;
		}

		public CoreTxData()
		{
		}

		public class BoughtOffersItemRecord
		{
			[CandidName("add")]
			public OptionalValue<List<offerId>> Add { get; set; }

			[CandidName("remove")]
			public OptionalValue<List<offerId>> Remove { get; set; }

			public BoughtOffersItemRecord(OptionalValue<List<offerId>> add, OptionalValue<List<offerId>> remove)
			{
				this.Add = add;
				this.Remove = remove;
			}

			public BoughtOffersItemRecord()
			{
			}
		}

		public class ItemsItemRecord
		{
			[CandidName("add")]
			public OptionalValue<List<Item>> Add { get; set; }

			[CandidName("remove")]
			public OptionalValue<List<Item>> Remove { get; set; }

			public ItemsItemRecord(OptionalValue<List<Item>> add, OptionalValue<List<Item>> remove)
			{
				this.Add = add;
				this.Remove = remove;
			}

			public ItemsItemRecord()
			{
			}
		}
	}
}